# Jetpack Compose Patterns

UI patterns following NowInAndroid and Material 3 guidelines.

## Table of Contents
1. [Screen Architecture](#screen-architecture)
2. [State Management](#state-management)
3. [Component Patterns](#component-patterns)
4. [Navigation](#navigation)
5. [Theming](#theming)
6. [Previews](#previews)

## Screen Architecture

### Route-Screen Pattern

Separate navigation concerns from UI:

```kotlin
// Route: Handles ViewModel, navigation callbacks
@Composable
internal fun TopicRoute(
    onBackClick: () -> Unit,
    onTopicClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TopicViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    TopicScreen(
        uiState = uiState,
        onBackClick = onBackClick,
        onTopicClick = onTopicClick,
        onFollowClick = viewModel::followTopic,
        modifier = modifier,
    )
}

// Screen: Pure UI, receives all data and callbacks as parameters
@Composable
internal fun TopicScreen(
    uiState: TopicUiState,
    onBackClick: () -> Unit,
    onTopicClick: (String) -> Unit,
    onFollowClick: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    when (uiState) {
        TopicUiState.Loading -> LoadingState(modifier)
        is TopicUiState.Error -> ErrorState(uiState.message, modifier)
        is TopicUiState.Success -> TopicContent(
            topic = uiState.topic,
            onBackClick = onBackClick,
            onTopicClick = onTopicClick,
            onFollowClick = onFollowClick,
            modifier = modifier,
        )
    }
}
```

### Benefits
- Screen is testable without ViewModel
- Clear separation of concerns
- Previews work without Hilt

## State Management

### Sealed Interface for UI State

```kotlin
sealed interface TopicUiState {
    data object Loading : TopicUiState
    
    data class Error(
        val message: String,
    ) : TopicUiState
    
    data class Success(
        val topic: FollowableTopic,
        val newsResources: List<UserNewsResource>,
    ) : TopicUiState
}
```

### StateFlow in ViewModel

```kotlin
@HiltViewModel
class TopicViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val topicsRepository: TopicsRepository,
    getUserNewsResourcesUseCase: GetUserNewsResourcesUseCase,
) : ViewModel() {

    private val topicId: String = savedStateHandle.toRoute<TopicRoute>().id

    val uiState: StateFlow<TopicUiState> = combine(
        topicsRepository.getTopic(topicId),
        getUserNewsResourcesUseCase(filterTopicIds = setOf(topicId)),
    ) { topic, newsResources ->
        TopicUiState.Success(
            topic = topic,
            newsResources = newsResources,
        )
    }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = TopicUiState.Loading,
        )

    fun followTopic(followed: Boolean) {
        viewModelScope.launch {
            topicsRepository.setTopicFollowed(topicId, followed)
        }
    }
}
```

### Collecting State in Compose

```kotlin
@Composable
fun TopicRoute(viewModel: TopicViewModel = hiltViewModel()) {
    // Use collectAsStateWithLifecycle for lifecycle-aware collection
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    TopicScreen(uiState = uiState)
}
```

## Component Patterns

### Stateless Components

```kotlin
@Composable
fun NiaTopicTag(
    text: String,
    followed: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FilterChip(
        selected = followed,
        onClick = onClick,
        label = { Text(text) },
        modifier = modifier,
        leadingIcon = if (followed) {
            { Icon(NiaIcons.Check, contentDescription = null) }
        } else null,
    )
}
```

### List Items

```kotlin
@Composable
fun NewsResourceCard(
    userNewsResource: UserNewsResource,
    isBookmarked: Boolean,
    onClick: () -> Unit,
    onToggleBookmark: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        onClick = onClick,
        modifier = modifier,
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            NewsResourceHeaderImage(userNewsResource.headerImageUrl)
            Spacer(modifier = Modifier.height(12.dp))
            NewsResourceTitle(userNewsResource.title)
            Spacer(modifier = Modifier.height(8.dp))
            NewsResourceMetaData(
                publishDate = userNewsResource.publishDate,
                resourceType = userNewsResource.type,
            )
            Spacer(modifier = Modifier.height(12.dp))
            NewsResourceShortDescription(userNewsResource.content)
            Spacer(modifier = Modifier.height(12.dp))
            NewsResourceTopics(userNewsResource.topics)
            BookmarkButton(
                isBookmarked = isBookmarked,
                onClick = onToggleBookmark,
            )
        }
    }
}
```

### Lazy Lists

```kotlin
@Composable
fun NewsFeed(
    feedState: NewsFeedUiState,
    onNewsResourcesCheckedChanged: (String, Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        when (feedState) {
            NewsFeedUiState.Loading -> {
                item { LoadingIndicator() }
            }
            is NewsFeedUiState.Success -> {
                items(
                    items = feedState.feed,
                    key = { it.id },
                ) { userNewsResource ->
                    NewsResourceCard(
                        userNewsResource = userNewsResource,
                        isBookmarked = userNewsResource.isSaved,
                        onClick = { /* navigate */ },
                        onToggleBookmark = {
                            onNewsResourcesCheckedChanged(
                                userNewsResource.id,
                                !userNewsResource.isSaved,
                            )
                        },
                    )
                }
            }
        }
    }
}
```

## Navigation

### Type-Safe Navigation (Navigation 2.8+)

```kotlin
// Define route in api module
@Serializable
data class TopicRoute(val id: String)

// Navigation function
fun NavController.navigateToTopic(topicId: String) {
    navigate(TopicRoute(topicId))
}

// NavGraph setup in impl module
fun NavGraphBuilder.topicScreen(
    onBackClick: () -> Unit,
    onTopicClick: (String) -> Unit,
) {
    composable<TopicRoute> {
        TopicRoute(
            onBackClick = onBackClick,
            onTopicClick = onTopicClick,
        )
    }
}

// Reading route in ViewModel
@HiltViewModel
class TopicViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val topicId: String = savedStateHandle.toRoute<TopicRoute>().id
}
```

### App-Level Navigation

```kotlin
@Composable
fun NiaNavHost(
    navController: NavHostController,
    onShowSnackbar: suspend (String, String?) -> Boolean,
    modifier: Modifier = Modifier,
) {
    NavHost(
        navController = navController,
        startDestination = ForYouRoute,
        modifier = modifier,
    ) {
        forYouScreen(
            onTopicClick = navController::navigateToTopic,
        )
        topicScreen(
            onBackClick = navController::popBackStack,
            onTopicClick = navController::navigateToTopic,
        )
        interestsGraph(
            onTopicClick = navController::navigateToTopic,
            nestedGraphs = {
                topicScreen(
                    onBackClick = navController::popBackStack,
                    onTopicClick = navController::navigateToTopic,
                )
            },
        )
    }
}
```

## Theming

### Design System Setup

```kotlin
// Theme.kt in core:designsystem
@Composable
fun NiaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = NiaTypography,
        content = content,
    )
}
```

### Icons

```kotlin
// NiaIcons.kt in core:designsystem
object NiaIcons {
    val Add = Icons.Rounded.Add
    val ArrowBack = Icons.AutoMirrored.Rounded.ArrowBack
    val Bookmark = Icons.Rounded.Bookmark
    val BookmarkBorder = Icons.Rounded.BookmarkBorder
    val Check = Icons.Rounded.Check
    val Settings = Icons.Rounded.Settings
}
```

## Previews

### Preview Annotations

```kotlin
@Preview(name = "Light")
@Preview(name = "Dark", uiMode = Configuration.UI_MODE_NIGHT_YES)
annotation class ThemePreviews

@Preview(name = "Phone", device = Devices.PHONE)
@Preview(name = "Tablet", device = Devices.TABLET)
annotation class DevicePreviews
```

### Preview Implementation

```kotlin
@ThemePreviews
@Composable
private fun TopicScreenPreview() {
    NiaTheme {
        TopicScreen(
            uiState = TopicUiState.Success(
                topic = previewTopic,
                newsResources = previewNewsResources,
            ),
            onBackClick = {},
            onTopicClick = {},
            onFollowClick = {},
        )
    }
}

// Preview data
private val previewTopic = FollowableTopic(
    topic = Topic(
        id = "1",
        name = "Jetpack Compose",
        shortDescription = "Modern Android UI toolkit",
        longDescription = "...",
        imageUrl = "https://...",
    ),
    isFollowed = true,
)
```

### Preview Provider

```kotlin
class TopicPreviewParameterProvider : PreviewParameterProvider<TopicUiState> {
    override val values: Sequence<TopicUiState> = sequenceOf(
        TopicUiState.Loading,
        TopicUiState.Error("Network error"),
        TopicUiState.Success(previewTopic, previewNewsResources),
    )
}

@ThemePreviews
@Composable
private fun TopicScreenPreview(
    @PreviewParameter(TopicPreviewParameterProvider::class) uiState: TopicUiState,
) {
    NiaTheme {
        TopicScreen(uiState = uiState, /* ... */)
    }
}
```

## Adaptive Layouts

```kotlin
@Composable
fun NiaApp(
    windowSizeClass: WindowSizeClass,
) {
    val shouldShowNavRail = windowSizeClass.widthSizeClass != WindowWidthSizeClass.Compact
    
    Row {
        if (shouldShowNavRail) {
            NiaNavRail(/* ... */)
        }
        
        Column {
            NiaNavHost(/* ... */)
            
            if (!shouldShowNavRail) {
                NiaBottomBar(/* ... */)
            }
        }
    }
}
```
