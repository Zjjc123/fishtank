# Fishtank - Focus App 🐠

A gamified focus and productivity app for iOS that helps you stay focused by blocking distracting apps and rewarding you with collectible fish for completing focus sessions.

## Overview

Fishtank transforms your focus time into an engaging experience. Start a focus session, block distracting apps, and earn collectible fish as rewards. Watch your fish swim in a beautiful animated tank as you build your collection and track your focus time.

## Features

### 🎯 Focus Sessions
- **Multiple Duration Options**: Choose from 15 minutes, 30 minutes, 1 hour, or 2 hours
- **App Blocking**: Uses iOS Screen Time API to block distracting apps during focus sessions
- **Progress Tracking**: Real-time progress display with time remaining
- **Background Completion**: Sessions continue even when the app is in the background
- **Speed Boost**: Optional in-app purchase to progress 50% faster through focus sessions

### 🐠 Fish Collection
- **50+ Unique Fish Species**: Collect a diverse range of fish with unique designs
- **7 Rarity Tiers**: Common, Uncommon, Rare, Epic, Legendary, Mythic, and Unique
- **Shiny Variants**: Special shiny versions of fish for extra rarity
- **Animated Tank**: Watch up to 20 fish swim in real-time with smooth animations
- **Interactive Fish**: Tap fish to startle them and watch them swim away
- **Collection Management**: Show/hide fish, rename favorites, and organize your collection

### 🎁 Lootbox System
- **Reward Lootboxes**: Earn lootboxes by completing focus sessions
  - Basic (15 min) → Basic Lootbox
  - Silver (30 min) → Silver Lootbox
  - Gold (1 hour) → Gold Lootbox
  - Platinum (2 hours) → Platinum Lootbox
- **Case Opening Animation**: Exciting wheel-based case opening experience
- **Rarity Probabilities**: Higher-tier lootboxes have better chances for rare fish

### ☁️ Cloud Sync
- **Supabase Integration**: Sync your collection and progress across devices
- **Guest Mode**: Play without an account, then migrate data when you sign up
- **Automatic Sync**: Data syncs automatically every 5 minutes and on app launch
- **Offline Support**: Works offline with local storage, syncs when online

### 🎨 Visual Experience
- **Landscape-Oriented**: Optimized for landscape viewing
- **Dynamic Backgrounds**: Beautiful animated backgrounds that change with time
- **Bubble Effects**: Animated bubbles for immersive atmosphere
- **Smooth Animations**: 60 FPS animations for fish movement and interactions

### 💰 In-App Purchases
- **Backgrounds Pack**: Unlock additional tank backgrounds
- **Platinum Lootboxes**: Purchase premium lootboxes for rare fish
- **Speed Boost**: Progress through focus sessions 50% faster

### 📊 Statistics & Sharing
- **Focus Time Tracking**: Track total time spent focusing
- **Collection Stats**: View fish counts by rarity
- **Share Your Progress**: Share your collection and stats with friends
- **Export Data**: Export your fish collection as JSON

## Architecture

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **Supabase**: Backend-as-a-Service for authentication and data sync
- **StoreKit**: In-app purchase management
- **Screen Time API**: App restriction functionality
- **Background Tasks**: Background processing for session completion

### Project Structure

```
Fishtank/
├── FishtankApp.swift          # App entry point and lifecycle management
├── ContentView.swift           # Main view with tank and UI
├── Models/                     # Data models
│   ├── Fish.swift              # Fish data model
│   ├── FishRarity.swift        # Rarity system
│   ├── FocusCommitment.swift   # Focus session types
│   ├── GameObjects.swift       # Game state objects
│   └── ...
├── Managers/                   # Business logic managers
│   ├── FishTankManager.swift   # Fish animation and tank management
│   ├── CommitmentManager.swift # Focus session management
│   ├── GameStateManager.swift  # Collection and stats management
│   ├── SupabaseManager.swift   # Cloud sync and authentication
│   ├── InAppPurchaseManager.swift
│   └── ...
├── Views/                      # SwiftUI views
│   ├── FishCollectionView.swift
│   ├── CommitmentSelectionView.swift
│   ├── SettingsView.swift
│   ├── StoreView.swift
│   └── ...
└── Assets.xcassets/           # Images and assets
```

### Key Components

#### Managers
- **FishTankManager**: Handles fish animation, positioning, and lootbox spawning
- **CommitmentManager**: Manages focus sessions, progress tracking, and app restrictions
- **GameStateManager**: Manages fish collection, statistics, and cloud sync
- **SupabaseManager**: Handles authentication and data synchronization
- **AppRestrictionManager**: Manages Screen Time API integration
- **BackgroundTaskManager**: Handles background task scheduling

#### Data Flow
1. User starts a focus session → `CommitmentManager`
2. App restrictions activate → `AppRestrictionManager`
3. Session completes → Lootbox spawned → `FishTankManager`
4. User opens lootbox → Fish added → `GameStateManager`
5. Fish collection synced → `SupabaseManager` (if authenticated)

## Setup & Installation

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- Swift 5.7 or later
- Supabase account (for cloud sync)

### Configuration

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fishtank
   ```

2. **Configure Supabase**
   - Create a Supabase project
   - Set up authentication (email/password)
   - Create database tables for fish collection and user profiles
   - Update `SupabaseConfig.swift` with your project URL and API key

3. **Configure In-App Purchases**
   - Set up products in App Store Connect
   - Update product IDs in `AppConfig.swift`
   - Configure StoreKit configuration file (`FishtankStoreKit.storekit`)

4. **Build and Run**
   - Open `Fishtank.xcodeproj` in Xcode
   - Select your development team
   - Build and run on simulator or device

### Supabase Schema

The app requires the following Supabase tables:

```sql
-- User profiles
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT,
  total_focus_time DOUBLE PRECISION DEFAULT 0,
  total_fish_caught INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Fish collection
CREATE TABLE fish_collection (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  fish_name TEXT NOT NULL,
  fish_image_name TEXT NOT NULL,
  rarity TEXT NOT NULL,
  size TEXT NOT NULL,
  is_shiny BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  custom_name TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Usage

### Starting a Focus Session
1. Tap the "Focus" button at the bottom of the screen
2. Select your desired session duration (15 min, 30 min, 1 hour, or 2 hours)
3. Grant Screen Time permissions if prompted
4. Your focus session begins and distracting apps are blocked

### Collecting Fish
1. Complete a focus session to earn a lootbox
2. Tap the lootbox in your tank to open it
3. Watch the case opening animation
4. Collect your new fish and watch them swim in your tank

### Managing Your Collection
1. Tap the "Collection" button to view all your fish
2. Filter by rarity or search by name
3. Tap a fish to rename it or toggle visibility
4. View statistics about your collection

### Cloud Sync
1. Sign up or log in through the Settings menu
2. Your collection automatically syncs to the cloud
3. Access your collection from any device
4. Guest mode allows you to play without an account

## Development

### Running Tests
```bash
# Run unit tests
xcodebuild test -scheme Fishtank -destination 'platform=iOS Simulator,name=iPhone 14'

# Run UI tests
xcodebuild test -scheme FishtankUITests -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain consistent naming conventions
- Document public APIs

### Adding New Fish
1. Add fish image to `Assets.xcassets`
2. Add fish entry to `FishDatabase.swift`
3. Assign appropriate rarity and size

### Adding New Features
1. Create feature branch
2. Implement feature following existing patterns
3. Add tests if applicable
4. Update documentation

## App Store

Download Fishtank on the App Store:
[App Store Link](https://apps.apple.com/us/app/fishtank-focus-app/id6747935306)

## License

Copyright © 2025 Jason Zhang. All rights reserved.

## Support

For issues, questions, or feature requests, please open an issue on GitHub or contact support through the app.

---

**Made with ❤️ to help you stay focused and productive**
