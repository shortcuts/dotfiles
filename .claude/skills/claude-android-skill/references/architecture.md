# Architecture Guide

Based on Google's official Android architecture guidance as implemented in NowInAndroid.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Layer](#data-layer)
3. [Domain Layer](#domain-layer)
4. [UI Layer](#ui-layer)
5. [Data Flow Example](#data-flow-example)

## Architecture Overview

Three-layer architecture with unidirectional data flow:
- **Events flow DOWN** (UI → Domain → Data)
- **Data flows UP** (Data → Domain → UI)
- **Local storage is source of truth**

```
┌────────────────────────────────────────────────────┐
│                    UI Layer                         │
│  ┌──────────────┐    ┌─────────────────────────┐   │
│  │   Screen     │◄───│      ViewModel          │   │
│  │  (Compose)   │    │  (StateFlow<UiState>)   │   │
│  └──────────────┘    └───────────┬─────────────┘   │
├──────────────────────────────────┼─────────────────┤
│                  Domain Layer    │                  │
│              ┌───────────────────▼──────┐          │
│              │       Use Cases          │          │
│              │  (combine/transform)     │          │
│              └───────────┬──────────────┘          │
├──────────────────────────┼─────────────────────────┤
│                  Data Layer                         │
│  ┌───────────────────────▼──────────────────────┐  │
│  │              Repository                       │  │
│  │    (offline-first, single source of truth)   │  │
│  └─────────┬─────────────────────┬──────────────┘  │
│            │                     │                  │
│  ┌─────────▼─────────┐  ┌───────▼──────────────┐  │
│  │  Local DataSource │  │  Remote DataSource   │  │
│  │   (Room + DAO)    │  │     (Retrofit)       │  │
│  └───────────────────┘  └──────────────────────┘  │
└────────────────────────────────────────────────────┘
```

## Data Layer

### Principles
- **Offline-first**: Local database is the source of truth
- **Repository pattern**: Single public API for data access
- **Reactive streams**: All data exposed as `Flow<T>`
- **No snapshots**: Never expose `getModel()`, always `getModelFlow()`

### Repository Implementation

```kotlin
// Public interface in core:data
interface TopicsRepository {
    fun getTopics(): Flow<List<Topic>>
    fun getTopic(id: String): Flow<Topic>
    suspend fun syncWith(synchronizer: Synchronizer): Boolean
}

// Implementation
internal class OfflineFirstTopicsRepository @Inject constructor(
    private val topicDao: TopicDao,
    private val network: NiaNetworkDataSource,
) : TopicsRepository {

    override fun getTopics(): Flow<List<Topic>> =
        topicDao.getTopicEntities()
            .map { entities -> entities.map(TopicEntity::asExternalModel) }

    override fun getTopic(id: String): Flow<Topic> =
        topicDao.getTopicEntity(id)
            .map(TopicEntity::asExternalModel)

    override suspend fun syncWith(synchronizer: Synchronizer): Boolean =
        synchronizer.changeListSync(
            versionReader = ChangeListVersions::topicVersion,
            changeListFetcher = { network.getTopicChangeList(after = it) },
            versionUpdater = { latestVersion ->
                copy(topicVersion = latestVersion)
            },
            modelDeleter = topicDao::deleteTopics,
            modelUpdater = { changedIds ->
                val networkTopics = network.getTopics(ids = changedIds)
                topicDao.upsertTopics(networkTopics.map(NetworkTopic::asEntity))
            },
        )
}
```

### Data Sources

| Type | Implementation | Purpose |
|------|----------------|---------|
| Local | Room DAO | Persistent storage, source of truth |
| Remote | Retrofit API | Network data fetching |
| Preferences | Proto DataStore | User settings, simple key-value |

### Room DAO Pattern

```kotlin
@Dao
interface TopicDao {
    @Query("SELECT * FROM topics")
    fun getTopicEntities(): Flow<List<TopicEntity>>

    @Query("SELECT * FROM topics WHERE id = :topicId")
    fun getTopicEntity(topicId: String): Flow<TopicEntity>

    @Upsert
    suspend fun upsertTopics(entities: List<TopicEntity>)

    @Query("DELETE FROM topics WHERE id IN (:ids)")
    suspend fun deleteTopics(ids: List<String>)
}
```

### Model Mapping

```kotlin
// Entity (database model) → External model (domain)
fun TopicEntity.asExternalModel() = Topic(
    id = id,
    name = name,
    shortDescription = shortDescription,
    longDescription = longDescription,
    imageUrl = imageUrl,
)

// Network model → Entity
fun NetworkTopic.asEntity() = TopicEntity(
    id = id,
    name = name,
    shortDescription = shortDescription,
    longDescription = longDescription,
    url = url,
    imageUrl = imageUrl,
)
```

### Data Synchronization

```kotlin
// WorkManager handles sync scheduling
class SyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val newsRepository: NewsRepository,
    private val topicsRepository: TopicsRepository,
) : CoroutineWorker(context, params), Synchronizer {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val syncedSuccessfully = listOf(
            newsRepository.syncWith(this@SyncWorker),
            topicsRepository.syncWith(this@SyncWorker),
        ).all { it }

        if (syncedSuccessfully) Result.success()
        else Result.retry()
    }
}
```

## Domain Layer

### Purpose
- Encapsulate complex business logic
- Remove duplicate logic from ViewModels
- Combine and transform data from multiple repositories
- **Optional layer** - only add when needed

### Use Case Pattern

```kotlin
class GetUserNewsResourcesUseCase @Inject constructor(
    private val newsRepository: NewsRepository,
    private val userDataRepository: UserDataRepository,
) {
    operator fun invoke(): Flow<List<UserNewsResource>> =
        newsRepository.getNewsResources()
            .combine(userDataRepository.userData) { newsResources, userData ->
                newsResources.mapToUserNewsResources(userData)
            }
}
```

### When to Create Use Cases
- Logic is reused across multiple ViewModels
- Complex data transformations
- Combining data from multiple repositories
- Business rules that don't belong in UI or Data layer

## UI Layer

### Components
- **Screen**: Composable UI elements
- **ViewModel**: Holds and manages UI state
- **UiState**: Sealed interface representing all possible states

### UiState Modeling

```kotlin
sealed interface ForYouUiState {
    data object Loading : ForYouUiState
    
    data class Success(
        val feed: List<UserNewsResource>,
        val isRefreshing: Boolean = false,
    ) : ForYouUiState
}
```

### ViewModel Pattern

```kotlin
@HiltViewModel
class ForYouViewModel @Inject constructor(
    private val getUserNewsResourcesUseCase: GetUserNewsResourcesUseCase,
    private val userDataRepository: UserDataRepository,
) : ViewModel() {

    val uiState: StateFlow<ForYouUiState> = 
        getUserNewsResourcesUseCase()
            .map(ForYouUiState::Success)
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.WhileSubscribed(5_000),
                initialValue = ForYouUiState.Loading,
            )

    fun setNewsResourceBookmarked(newsResourceId: String, bookmarked: Boolean) {
        viewModelScope.launch {
            userDataRepository.setNewsResourceBookmarked(newsResourceId, bookmarked)
        }
    }
}
```

### Screen Composition

```kotlin
@Composable
internal fun ForYouRoute(
    onTopicClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ForYouViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    ForYouScreen(
        uiState = uiState,
        onTopicClick = onTopicClick,
        onBookmarkChange = viewModel::setNewsResourceBookmarked,
        modifier = modifier,
    )
}

@Composable
internal fun ForYouScreen(
    uiState: ForYouUiState,
    onTopicClick: (String) -> Unit,
    onBookmarkChange: (String, Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    when (uiState) {
        ForYouUiState.Loading -> LoadingState()
        is ForYouUiState.Success -> {
            LazyColumn(modifier = modifier) {
                items(uiState.feed) { userNewsResource ->
                    NewsResourceCard(
                        userNewsResource = userNewsResource,
                        onClick = { onTopicClick(userNewsResource.id) },
                        onBookmarkChange = { onBookmarkChange(userNewsResource.id, it) },
                    )
                }
            }
        }
    }
}
```

## Data Flow Example

**Scenario**: Display news on For You screen

1. **App startup** → WorkManager enqueues sync job
2. **ViewModel** calls `GetUserNewsResourcesUseCase`, emits `Loading` state
3. **UserDataRepository** emits user preferences from DataStore
4. **SyncWorker** executes, calls repository's `syncWith()`
5. **Repository** fetches from network via Retrofit
6. **Repository** writes to local Room database
7. **Room DAO** emits updated data into Flow
8. **Repository** transforms entity → domain model
9. **UseCase** combines news with user data
10. **ViewModel** receives combined data, emits `Success` state
11. **Screen** recomposes with new data
