# Testing Patterns

Testing approach following NowInAndroid's test doubles strategy (no mocking libraries).

## Table of Contents
1. [Testing Philosophy](#testing-philosophy)
2. [Test Doubles](#test-doubles)
3. [ViewModel Tests](#viewmodel-tests)
4. [Repository Tests](#repository-tests)
5. [UI Tests](#ui-tests)
6. [Test Utilities](#test-utilities)

## Testing Philosophy

### No Mocking Libraries

NowInAndroid does NOT use mocking libraries (Mockito, MockK). Instead:
- Create test doubles that implement the same interfaces
- Test doubles provide realistic implementations with test hooks
- Results in less brittle tests that exercise more production code

### Test Types

| Type | Location | Runner | Purpose |
|------|----------|--------|---------|
| Unit tests | `src/test/` | JVM | ViewModel, Repository logic |
| UI tests | `src/androidTest/` | Device/Emulator | Compose UI, integration |
| Screenshot tests | `src/test/` | Roborazzi | Visual regression |

## Test Doubles

### Test Repository Pattern

```kotlin
// In core:testing module
class TestTopicsRepository : TopicsRepository {

    private val topicsFlow = MutableSharedFlow<List<Topic>>(replay = 1)
    private val followedTopicsFlow = MutableSharedFlow<Set<String>>(replay = 1)

    // Test hooks
    fun sendTopics(topics: List<Topic>) {
        topicsFlow.tryEmit(topics)
    }

    fun sendFollowedTopics(ids: Set<String>) {
        followedTopicsFlow.tryEmit(ids)
    }

    // Interface implementation
    override fun getTopics(): Flow<List<Topic>> = topicsFlow

    override fun getTopic(id: String): Flow<Topic> =
        topicsFlow.map { topics -> topics.first { it.id == id } }

    override suspend fun setTopicFollowed(topicId: String, followed: Boolean) {
        val current = followedTopicsFlow.replayCache.firstOrNull() ?: emptySet()
        followedTopicsFlow.emit(
            if (followed) current + topicId else current - topicId
        )
    }

    override suspend fun syncWith(synchronizer: Synchronizer): Boolean = true
}
```

### Test DataSource Pattern

```kotlin
class TestNiaPreferencesDataSource : NiaPreferencesDataSource {

    private val userDataFlow = MutableStateFlow(emptyUserData())

    // Test hooks
    fun setUserData(userData: UserData) {
        userDataFlow.value = userData
    }

    // Interface implementation
    override val userData: Flow<UserData> = userDataFlow

    override suspend fun setFollowedTopicIds(topicIds: Set<String>) {
        userDataFlow.update { it.copy(followedTopics = topicIds) }
    }

    override suspend fun setBookmarkedNewsResourceIds(ids: Set<String>) {
        userDataFlow.update { it.copy(bookmarkedNewsResources = ids) }
    }
}
```

### Test Network DataSource

```kotlin
class TestNiaNetworkDataSource : NiaNetworkDataSource {

    private var topicsResponse: List<NetworkTopic> = emptyList()
    private var newsResourcesResponse: List<NetworkNewsResource> = emptyList()

    // Test hooks
    fun setTopicsResponse(topics: List<NetworkTopic>) {
        topicsResponse = topics
    }

    fun setNewsResourcesResponse(newsResources: List<NetworkNewsResource>) {
        newsResourcesResponse = newsResources
    }

    // Interface implementation
    override suspend fun getTopics(ids: List<String>?): List<NetworkTopic> =
        if (ids != null) topicsResponse.filter { it.id in ids }
        else topicsResponse

    override suspend fun getNewsResources(ids: List<String>?): List<NetworkNewsResource> =
        if (ids != null) newsResourcesResponse.filter { it.id in ids }
        else newsResourcesResponse
}
```

## ViewModel Tests

### Setup with Test Rule

```kotlin
class TopicViewModelTest {

    @get:Rule
    val dispatcherRule = TestDispatcherRule()

    private val topicsRepository = TestTopicsRepository()
    private val userDataRepository = TestUserDataRepository()

    private lateinit var viewModel: TopicViewModel

    @Before
    fun setup() {
        viewModel = TopicViewModel(
            savedStateHandle = SavedStateHandle(mapOf("topicId" to testTopic.id)),
            topicsRepository = topicsRepository,
            userDataRepository = userDataRepository,
        )
    }

    @Test
    fun `uiState is Loading when initialized`() = runTest {
        assertEquals(TopicUiState.Loading, viewModel.uiState.value)
    }

    @Test
    fun `uiState is Success when topic data is available`() = runTest {
        // Send test data through test doubles
        topicsRepository.sendTopics(listOf(testTopic))
        userDataRepository.setUserData(testUserData)

        // Collect state
        val uiState = viewModel.uiState.first { it is TopicUiState.Success }

        // Assert
        assertTrue(uiState is TopicUiState.Success)
        assertEquals(testTopic.id, (uiState as TopicUiState.Success).topic.id)
    }

    @Test
    fun `followTopic updates repository`() = runTest {
        // Setup
        topicsRepository.sendTopics(listOf(testTopic))
        userDataRepository.setUserData(testUserData.copy(followedTopics = emptySet()))

        // Act
        viewModel.followTopic(true)

        // Assert
        val userData = userDataRepository.userData.first()
        assertTrue(testTopic.id in userData.followedTopics)
    }
}
```

### Test Dispatcher Rule

```kotlin
// In core:testing module
class TestDispatcherRule(
    private val testDispatcher: TestDispatcher = UnconfinedTestDispatcher(),
) : TestWatcher() {

    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }

    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
```

### Testing StateFlow with Turbine

```kotlin
@Test
fun `uiState emits Loading then Success`() = runTest {
    viewModel.uiState.test {
        // Initial state
        assertEquals(TopicUiState.Loading, awaitItem())

        // Send data
        topicsRepository.sendTopics(listOf(testTopic))
        userDataRepository.setUserData(testUserData)

        // Success state
        val successState = awaitItem()
        assertTrue(successState is TopicUiState.Success)

        cancelAndIgnoreRemainingEvents()
    }
}
```

## Repository Tests

### Testing Offline-First Repository

```kotlin
class OfflineFirstTopicsRepositoryTest {

    private val topicDao = TestTopicDao()
    private val network = TestNiaNetworkDataSource()

    private lateinit var repository: TopicsRepository

    @Before
    fun setup() {
        repository = OfflineFirstTopicsRepository(
            topicDao = topicDao,
            network = network,
        )
    }

    @Test
    fun `getTopics returns data from local database`() = runTest {
        // Setup - add data to test DAO
        topicDao.upsertTopics(testTopicEntities)

        // Act
        val topics = repository.getTopics().first()

        // Assert
        assertEquals(testTopicEntities.size, topics.size)
        assertEquals(testTopicEntities.first().id, topics.first().id)
    }

    @Test
    fun `syncWith fetches from network and updates database`() = runTest {
        // Setup
        network.setTopicsResponse(testNetworkTopics)

        // Act
        val result = repository.syncWith(TestSynchronizer())

        // Assert
        assertTrue(result)
        val localTopics = topicDao.getTopicEntities().first()
        assertEquals(testNetworkTopics.size, localTopics.size)
    }
}
```

### Test DAO with In-Memory Database

```kotlin
class TopicDaoTest {

    private lateinit var database: NiaDatabase
    private lateinit var topicDao: TopicDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            NiaDatabase::class.java,
        ).build()
        topicDao = database.topicDao()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun `upsertTopics inserts new topics`() = runTest {
        topicDao.upsertTopics(testTopicEntities)

        val topics = topicDao.getTopicEntities().first()
        assertEquals(testTopicEntities.size, topics.size)
    }

    @Test
    fun `deleteTopics removes topics by id`() = runTest {
        topicDao.upsertTopics(testTopicEntities)
        topicDao.deleteTopics(listOf(testTopicEntities.first().id))

        val topics = topicDao.getTopicEntities().first()
        assertEquals(testTopicEntities.size - 1, topics.size)
    }
}
```

## UI Tests

### Compose UI Tests

```kotlin
class TopicScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun `loading state shows progress indicator`() {
        composeTestRule.setContent {
            NiaTheme {
                TopicScreen(
                    uiState = TopicUiState.Loading,
                    onBackClick = {},
                    onTopicClick = {},
                    onFollowClick = {},
                )
            }
        }

        composeTestRule
            .onNodeWithTag("loadingIndicator")
            .assertIsDisplayed()
    }

    @Test
    fun `success state shows topic content`() {
        composeTestRule.setContent {
            NiaTheme {
                TopicScreen(
                    uiState = TopicUiState.Success(
                        topic = testFollowableTopic,
                        newsResources = testNewsResources,
                    ),
                    onBackClick = {},
                    onTopicClick = {},
                    onFollowClick = {},
                )
            }
        }

        composeTestRule
            .onNodeWithText(testFollowableTopic.topic.name)
            .assertIsDisplayed()
    }

    @Test
    fun `clicking follow button triggers callback`() {
        var followClicked = false

        composeTestRule.setContent {
            NiaTheme {
                TopicScreen(
                    uiState = TopicUiState.Success(testFollowableTopic, emptyList()),
                    onBackClick = {},
                    onTopicClick = {},
                    onFollowClick = { followClicked = true },
                )
            }
        }

        composeTestRule
            .onNodeWithContentDescription("Follow")
            .performClick()

        assertTrue(followClicked)
    }
}
```

### Hilt UI Tests

```kotlin
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class TopicScreenIntegrationTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<HiltComponentActivity>()

    @Inject
    lateinit var topicsRepository: TopicsRepository

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun topicScreenDisplaysDataFromRepository() {
        // Test with real (test) DI graph
        composeTestRule.setContent {
            TopicRoute(
                onBackClick = {},
                onTopicClick = {},
            )
        }

        // Assertions
    }
}
```

## Test Utilities

### Test Data Factories

```kotlin
// In core:testing module
object TestData {
    val testTopic = Topic(
        id = "test-topic-1",
        name = "Test Topic",
        shortDescription = "Short description",
        longDescription = "Long description",
        imageUrl = "https://example.com/image.png",
    )

    val testFollowableTopic = FollowableTopic(
        topic = testTopic,
        isFollowed = false,
    )

    val testNewsResource = NewsResource(
        id = "test-news-1",
        title = "Test News",
        content = "Test content",
        url = "https://example.com/news",
        headerImageUrl = "https://example.com/header.png",
        publishDate = Instant.parse("2024-01-01T00:00:00Z"),
        type = NewsResourceType.Article,
        topics = listOf(testTopic),
    )

    val testUserData = UserData(
        bookmarkedNewsResources = setOf("test-news-1"),
        followedTopics = setOf("test-topic-1"),
        themeBrand = ThemeBrand.DEFAULT,
        darkThemeConfig = DarkThemeConfig.FOLLOW_SYSTEM,
        useDynamicColor = true,
        shouldHideOnboarding = false,
    )
}
```

### Custom Test Runner

```kotlin
// In core:testing module
class NiaTestRunner : AndroidJUnitRunner() {
    override fun newApplication(
        cl: ClassLoader?,
        name: String?,
        context: Context?,
    ): Application = super.newApplication(cl, HiltTestApplication::class.java.name, context)
}
```

### Gradle Test Configuration

```kotlin
// Module build.gradle.kts
android {
    defaultConfig {
        testInstrumentationRunner = "com.example.core.testing.NiaTestRunner"
    }
}

dependencies {
    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.turbine)

    androidTestImplementation(libs.androidx.test.ext)
    androidTestImplementation(libs.hilt.android.testing)
    kspAndroidTest(libs.hilt.android.compiler)

    testImplementation(projects.core.testing)
    androidTestImplementation(projects.core.testing)
}
```

## Running Tests

```bash
# Run all unit tests for demo debug
./gradlew testDemoDebug

# Run instrumented tests
./gradlew connectedDemoDebugAndroidTest

# Run specific module tests
./gradlew :feature:topic:impl:testDemoDebug

# Screenshot tests (Roborazzi)
./gradlew recordRoborazziDemoDebug  # Record baseline
./gradlew verifyRoborazziDemoDebug  # Verify against baseline
```
