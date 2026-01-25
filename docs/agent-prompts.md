# Playdate Development Agent Prompts

Use these prompts with Claude Code or any AI-powered IDE to accelerate your Playdate game development.

## Getting Started

### Basic Game Structure
```
Create a basic Playdate game structure with:
- A player sprite that moves with the D-pad
- Screen boundary collision
- A simple score counter
- Game over state when pressing B button
```

### Crank-Based Game
```
Create a Playdate game that uses the crank as the primary input:
- Player controls a rotating object with the crank
- Objects spawn from the edges
- Player must align rotation to "catch" objects
- Track score and show game over screen
```

## Game Mechanics

### Add Sprite Animation
```
Add sprite animation to my Playdate game:
- Create an AnimatedSprite class
- Support for multiple animation states (idle, walk, jump)
- Frame-based animation with configurable speed
- Direction flipping for left/right movement
```

### Implement Tilemap
```
Implement a tilemap system for my Playdate game:
- Load a tilemap from a simple text file or table
- Support solid tiles for collision
- Camera scrolling that follows the player
- Efficient rendering using dirty rectangles
```

### Add Particle System
```
Create a simple particle system for Playdate:
- Particles spawn at a position with random velocities
- Support for gravity and drag
- Fade out over lifetime
- Object pooling for performance
```

### Implement State Machine
```
Create a game state machine for Playdate:
- States: Menu, Playing, Paused, GameOver
- Clean transitions between states
- Each state handles its own input and rendering
- Easy to add new states
```

## UI Components

### Create Menu System
```
Create a menu system for my Playdate game:
- Crank-controlled selection (like a dial)
- Visual feedback for current selection
- Support for nested submenus
- Sound effects for navigation
```

### Add Dialog System
```
Implement a dialog/text box system:
- Character-by-character text reveal
- Support for multiple pages
- A button to advance, B to skip
- Optional character portrait support
```

### Create HUD
```
Create a HUD overlay for my game:
- Health bar (hearts or bar style)
- Score display with animated counting
- Timer display
- Item inventory slots
```

## Audio

### Add Sound Effects
```
Set up a sound effect system:
- Preload common sounds (jump, collect, hit)
- Support for pitch variation
- Volume control
- Don't overlap same sound too quickly
```

### Add Music System
```
Implement background music:
- Looping music playback
- Fade in/out transitions
- Multiple tracks for different game states
- Pause/resume with game state
```

## Save System

### Implement Save/Load
```
Create a save game system:
- Save player progress, score, and settings
- Load on game start
- Auto-save on game pause/exit
- Handle missing or corrupted save data
```

## Performance

### Optimize Rendering
```
Help me optimize my Playdate game's rendering:
- Identify what's being redrawn unnecessarily
- Implement dirty rectangle tracking
- Use sprites efficiently
- Profile and target 30 FPS consistently
```

### Memory Management
```
Review my code for memory issues:
- Find potential memory leaks
- Optimize table usage
- Reduce garbage collection pauses
- Use object pooling where appropriate
```

## Complete Game Examples

### Breakout Clone
```
Create a complete Breakout/Arkanoid clone for Playdate:
- Crank-controlled paddle
- Ball physics with angle reflection
- 3 rows of destructible bricks
- Lives system (3 lives)
- Score tracking
- Game over and restart
```

### Endless Runner
```
Create an endless runner game for Playdate:
- Auto-scrolling background
- A button to jump
- Crank to control lane (3 lanes)
- Obstacles to avoid
- Collectibles for points
- Increasing difficulty over time
```

### Puzzle Game
```
Create a match-3 puzzle game for Playdate:
- 6x6 grid of symbols
- D-pad to move cursor
- A to select/swap
- Crank to rotate selected piece
- Match 3+ to clear
- Cascade falling pieces
- Score and level system
```

## Tips for Working with AI Agents

1. **Be Specific**: Include Playdate-specific requirements (1-bit graphics, 400x240 resolution, crank input)

2. **Mention Performance**: Always ask for Playdate-optimized code (local variables, object pooling)

3. **Request Comments**: Ask for well-commented code explaining Playdate-specific patterns

4. **Test Incrementally**: Build and test after each feature, don't try to generate entire games at once

5. **Provide Context**: Share your existing code structure so the agent can integrate properly
