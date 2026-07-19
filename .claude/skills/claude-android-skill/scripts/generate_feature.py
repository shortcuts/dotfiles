#!/usr/bin/env python3
"""
Feature Module Generator for Android projects following NowInAndroid patterns.

Usage:
    python generate_feature.py <feature-name> --package <package.name> --path <project-path>

Example:
    python generate_feature.py settings --package com.example.app --path /path/to/project
"""

import os
import sys
import argparse
from pathlib import Path


def to_pascal_case(name: str) -> str:
    """Convert kebab-case or snake_case to PascalCase."""
    return ''.join(word.capitalize() for word in name.replace('-', '_').split('_'))


def to_camel_case(name: str) -> str:
    """Convert kebab-case or snake_case to camelCase."""
    pascal = to_pascal_case(name)
    return pascal[0].lower() + pascal[1:] if pascal else ''


def create_directory(path: Path):
    """Create directory if it doesn't exist."""
    path.mkdir(parents=True, exist_ok=True)
    print(f"✅ Created: {path}")


def write_file(path: Path, content: str):
    """Write content to file."""
    path.write_text(content)
    print(f"✅ Created: {path}")


def generate_api_navigation(feature_name: str, package: str) -> str:
    """Generate navigation file for api module."""
    pascal = to_pascal_case(feature_name)
    upper_snake = feature_name.upper().replace('-', '_')
    
    return f'''package {package}.feature.{feature_name.replace('-', '')}.api

import androidx.navigation.NavController
import kotlinx.serialization.Serializable

@Serializable
data class {pascal}Route(val id: String? = null)

const val {upper_snake}_ROUTE = "{feature_name}"

fun NavController.navigateTo{pascal}(id: String? = null) {{
    navigate({pascal}Route(id))
}}
'''


def generate_api_build_gradle(package: str) -> str:
    """Generate build.gradle.kts for api module."""
    return f'''plugins {{
    alias(libs.plugins.nowinandroid.android.library)
    alias(libs.plugins.kotlin.serialization)
}}

android {{
    namespace = "{package}.feature.{{}}.api"
}}

dependencies {{
    api(projects.core.model)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.androidx.navigation.compose)
}}
'''


def generate_ui_state(feature_name: str, package: str) -> str:
    """Generate UiState sealed interface."""
    pascal = to_pascal_case(feature_name)
    
    return f'''package {package}.feature.{feature_name.replace('-', '')}.impl

sealed interface {pascal}UiState {{
    data object Loading : {pascal}UiState
    
    data class Success(
        val data: List<String> = emptyList(),
    ) : {pascal}UiState
    
    data class Error(
        val message: String,
    ) : {pascal}UiState
}}
'''


def generate_viewmodel(feature_name: str, package: str) -> str:
    """Generate ViewModel."""
    pascal = to_pascal_case(feature_name)
    camel = to_camel_case(feature_name)
    
    return f'''package {package}.feature.{feature_name.replace('-', '')}.impl

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class {pascal}ViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    // TODO: Inject repositories here
) : ViewModel() {{

    val uiState: StateFlow<{pascal}UiState> = flow {{
        // TODO: Replace with actual data flow
        emit({pascal}UiState.Success(data = listOf("Item 1", "Item 2")))
    }}
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = {pascal}UiState.Loading,
        )

    fun onAction(action: {pascal}Action) {{
        when (action) {{
            is {pascal}Action.ItemClicked -> handleItemClick(action.id)
        }}
    }}

    private fun handleItemClick(id: String) {{
        // TODO: Handle item click
    }}
}}

sealed interface {pascal}Action {{
    data class ItemClicked(val id: String) : {pascal}Action
}}
'''


def generate_screen(feature_name: str, package: str) -> str:
    """Generate Compose Screen."""
    pascal = to_pascal_case(feature_name)
    camel = to_camel_case(feature_name)
    
    return f'''package {package}.feature.{feature_name.replace('-', '')}.impl

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
internal fun {pascal}Route(
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: {pascal}ViewModel = hiltViewModel(),
) {{
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    {pascal}Screen(
        uiState = uiState,
        onAction = viewModel::onAction,
        onBackClick = onBackClick,
        modifier = modifier,
    )
}}

@Composable
internal fun {pascal}Screen(
    uiState: {pascal}UiState,
    onAction: ({pascal}Action) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier,
) {{
    when (uiState) {{
        is {pascal}UiState.Loading -> {{
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center,
            ) {{
                CircularProgressIndicator()
            }}
        }}
        is {pascal}UiState.Success -> {{
            {pascal}Content(
                data = uiState.data,
                onAction = onAction,
                modifier = modifier,
            )
        }}
        is {pascal}UiState.Error -> {{
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center,
            ) {{
                Text(
                    text = uiState.message,
                    color = MaterialTheme.colorScheme.error,
                )
            }}
        }}
    }}
}}

@Composable
private fun {pascal}Content(
    data: List<String>,
    onAction: ({pascal}Action) -> Unit,
    modifier: Modifier = Modifier,
) {{
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
    ) {{
        items(data) {{ item ->
            Text(
                text = item,
                modifier = Modifier.padding(vertical = 8.dp),
            )
        }}
    }}
}}

@Preview
@Composable
private fun {pascal}ScreenPreview() {{
    {pascal}Screen(
        uiState = {pascal}UiState.Success(
            data = listOf("Preview Item 1", "Preview Item 2"),
        ),
        onAction = {{}},
        onBackClick = {{}},
    )
}}
'''


def generate_navigation(feature_name: str, package: str) -> str:
    """Generate Navigation setup."""
    pascal = to_pascal_case(feature_name)
    
    return f'''package {package}.feature.{feature_name.replace('-', '')}.impl

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import {package}.feature.{feature_name.replace('-', '')}.api.{pascal}Route

fun NavGraphBuilder.{to_camel_case(feature_name)}Screen(
    onBackClick: () -> Unit,
) {{
    composable<{pascal}Route> {{
        {pascal}Route(
            onBackClick = onBackClick,
        )
    }}
}}
'''


def generate_impl_build_gradle(feature_name: str, package: str) -> str:
    """Generate build.gradle.kts for impl module."""
    return f'''plugins {{
    alias(libs.plugins.nowinandroid.android.feature)
    alias(libs.plugins.nowinandroid.android.library.compose)
}}

android {{
    namespace = "{package}.feature.{feature_name.replace('-', '')}.impl"
}}

dependencies {{
    api(projects.feature.{feature_name.replace('-', '')}.api)
    
    implementation(projects.core.data)
    implementation(projects.core.ui)
    implementation(projects.core.designsystem)
}}
'''


def generate_feature_module(feature_name: str, package: str, project_path: Path):
    """Generate complete feature module structure."""
    
    feature_dir = project_path / "feature" / feature_name.replace('-', '')
    api_dir = feature_dir / "api"
    impl_dir = feature_dir / "impl"
    
    api_src = api_dir / "src" / "main" / "kotlin" / package.replace('.', '/') / "feature" / feature_name.replace('-', '') / "api"
    impl_src = impl_dir / "src" / "main" / "kotlin" / package.replace('.', '/') / "feature" / feature_name.replace('-', '') / "impl"
    
    # Create directories
    create_directory(api_src)
    create_directory(impl_src)
    
    # Generate api module files
    write_file(api_dir / "build.gradle.kts", generate_api_build_gradle(package).replace('{}', feature_name.replace('-', '')))
    write_file(api_src / f"{to_pascal_case(feature_name)}Navigation.kt", generate_api_navigation(feature_name, package))
    
    # Generate impl module files
    write_file(impl_dir / "build.gradle.kts", generate_impl_build_gradle(feature_name, package))
    write_file(impl_src / f"{to_pascal_case(feature_name)}UiState.kt", generate_ui_state(feature_name, package))
    write_file(impl_src / f"{to_pascal_case(feature_name)}ViewModel.kt", generate_viewmodel(feature_name, package))
    write_file(impl_src / f"{to_pascal_case(feature_name)}Screen.kt", generate_screen(feature_name, package))
    write_file(impl_src / f"{to_pascal_case(feature_name)}Navigation.kt", generate_navigation(feature_name, package))
    
    print(f"\n✅ Feature module '{feature_name}' generated successfully!")
    print(f"\nNext steps:")
    print(f"1. Add to settings.gradle.kts:")
    print(f'   include(":feature:{feature_name.replace("-", "")}:api")')
    print(f'   include(":feature:{feature_name.replace("-", "")}:impl")')
    print(f"2. Add dependency in app/build.gradle.kts:")
    print(f'   implementation(projects.feature.{feature_name.replace("-", "")}.impl)')
    print(f"3. Add navigation in NiaNavHost")


def main():
    parser = argparse.ArgumentParser(description="Generate Android feature module")
    parser.add_argument("name", help="Feature name (kebab-case, e.g., 'user-profile')")
    parser.add_argument("--package", required=True, help="Base package name (e.g., 'com.example.app')")
    parser.add_argument("--path", required=True, help="Project root path")
    
    args = parser.parse_args()
    
    project_path = Path(args.path).resolve()
    
    if not project_path.exists():
        print(f"❌ Error: Project path does not exist: {project_path}")
        sys.exit(1)
    
    print(f"🚀 Generating feature module: {args.name}")
    print(f"   Package: {args.package}")
    print(f"   Path: {project_path}")
    print()
    
    generate_feature_module(args.name, args.package, project_path)


if __name__ == "__main__":
    main()
