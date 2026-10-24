# 🌾 Amrai: Godot 4 Mobile 3D Indian Village

A complete, commit-ready **Godot 4 Mobile 3D** project featuring a third-person player controller, intuitive mobile touch controls (left virtual joystick, right-side camera drag zone, action fire button), and a stylized low-poly Indian village environment.

---

## 🌟 Key Features

### 🕹️ Mobile Touch Controls
- **Left Virtual Joystick (`MobileVirtualJoystick`)**:
  - Multi-touch isolated with unique touch tracking (`InputEventScreenTouch`, `InputEventScreenDrag`).
  - Supports dynamic floating placement (appears where the thumb touches) or fixed positioning.
  - Configurable deadzone, clamping radius, and smooth reset on release.
  - High-DPI procedural vector drawing without blur.
- **Right-Side Camera Drag Zone (`TouchLookZone`)**:
  - Full-featured camera gimbal controller (Yaw on gimbal, Pitch on spring arm).
  - Pitch angle clamped between `-62°` (looking down) and `+32°` (looking up).
  - Smart touch exclusion system that prevents camera jumps when tapping the Fire Button.
- **Action / Fire Button (`FireButton`)**:
  - Stylized circular action button at bottom-right with custom procedural flame glyph.
  - Multi-touch isolated; animates on press (scale down, glow pulse).
  - Triggers player projectile casting and integrates with Godot's `fire` input action.
- **Desktop Fallback**:
  - Fully playable on PC/Mac with WASD keys, right mouse drag / Alt-click drag, and Spacebar.

### 👤 Third-Person Player Controller
- Camera-relative directional movement: moves forward, backward, left, and right relative to the camera gimbal.
- Smooth turn slerp towards moving direction.
- Procedural animations:
  - Subtle vertical body bobbing during movement.
  - Arm swinging on walk cycle.
  - Forward velocity lean into turns.
  - Firing recoil and muzzle flash effects.
- Stylized low-poly Indian character:
  - Saffron Pagri / Turban.
  - White Kurta with saffron sash / Kamarbandh.
  - Dhoti trousers.
  - Simple low-poly gun held in the right hand, with a visible barrel and firing muzzle.
  - Low-poly face details: eyes, eyebrows, nose, and mouth.

### 🏛️ Low-Poly Indian Village Scene
- **Sacred Banyan Tree (Bargad ka Ped)**:
  - Sprawling low-poly trunk, aerial roots, and lush layered canopy.
  - Elevated octagonal stone platform (**Chabutra**) where village elders gather.
- **Traditional Village Well (Kuan)**:
  - Stone masonry rim, overhead timber frame, pulley wheel, and brass bucket.
- **Village Houses (Kutcha & Pucca)**:
  - Mud-and-brick houses with sloping terracotta tiled roofs (**Khaprail**).
  - Front wooden verandas (**Otta**) with carved timber pillars and rustic doors.
  - Round conical thatch huts (**Jhopdi / Kutir**).
- **Rustic Village Props & Life**:
  - **Charpais / Khatiyas**: Woven rope cots with turned wooden legs and folded cotton sheets.
  - **Bullock Cart (Bailgadi)**: Traditional agricultural cart with spoked wooden wheels.
  - **Haystacks (Busa mounds)**: Conical mounds of dried straw with bamboo supports.
  - **Village Shrine (Mandir)**: Whitewashed stone plinth, tiered shikhara, and a fluttering saffron flag (**Dhwaja**).
  - **Fences**: Wooden split-rail boundary fences enclosing courtyards.
  - **Destructible Clay Pots (Matkas)**: Scattered near the well, under verandahs, and by the square. Shooting them triggers clay shard particle bursts and updates the on-screen shattered pot counter!

---

## 📁 Project Structure

```
my-first-app/
├── project.godot                     # Godot 4 project settings & mobile touch configuration
├── icon.svg                          # Stylized Indian village icon
├── .gitignore                        # Godot 4 gitignore (.godot/, .import/, etc.)
├── README.md                         # Project documentation
│
├── scenes/
│   ├── main.tscn                     # Main game world scene
│   ├── player/
│   │   ├── player.tscn               # CharacterBody3D, SpringArm3D, camera gimbal, visuals
│   │   └── projectile.tscn           # Magic projectile with trail & impact particles
│   ├── ui/
│   │   ├── virtual_controls.tscn     # CanvasLayer HUD with joystick, look zone, fire button
│   │   ├── virtual_joystick.tscn     # Mobile left virtual joystick
│   │   ├── touch_look_zone.tscn      # Mobile right camera drag zone
│   │   └── fire_button.tscn          # Mobile touch action/fire button
│   └── village/
│       ├── banyan_tree.tscn          # Banyan tree with chabutra platform
│       ├── village_well.tscn         # Traditional stone well with timber frame
│       ├── village_house.tscn        # Mud wall house with terracotta roof
│       ├── village_hut.tscn          # Cylindrical thatch roof hut
│       ├── charpai.tscn              # Woven wooden cot
│       ├── bullock_cart.tscn         # Wooden bullock cart with spoked wheels
│       ├── clay_pot.tscn             # Destructible terracotta matka
│       ├── haystack.tscn             # Conical straw haystack
│       ├── village_shrine.tscn       # Roadside mandir with saffron flag
│       └── village_boundary.tscn     # Split-rail wooden boundary fence
│
├── scripts/
│   ├── player/
│   │   ├── player.gd                 # Third-person character movement, camera, combat
│   │   └── projectile.gd             # Projectile velocity, lifetime, and hit logic
│   ├── ui/
│   │   ├── virtual_controls.gd       # CanvasLayer coordinator
│   │   ├── virtual_joystick.gd       # Multi-touch virtual joystick
│   │   ├── touch_look_zone.gd        # Multi-touch camera drag controller
│   │   └── fire_button.gd            # Action button with press animation & cooldown
│   └── world/
│       ├── main.gd                   # Main level script, HUD counter, signal routing
│       └── clay_pot.gd               # Destructible clay pot physics & particles
│
├── assets/
│   └── materials/
│       ├── mat_terracotta.tres       # Terracotta clay material
│       ├── mat_mud_wall.tres         # Earthy ochre mud wall
│       ├── mat_whitewash.tres        # Village whitewash trim
│       ├── mat_wood.tres             # Rustic dark teak/sal wood
│       ├── mat_thatch.tres           # Golden straw/thatch
│       ├── mat_foliage.tres          # Lush green banyan foliage
│       ├── mat_ground_dirt.tres      # Warm Indian soil/sand
│       ├── mat_stone.tres            # Porous masonry stone
│       ├── mat_cloth_saffron.tres    # Saffron / vermilion fabric
│       ├── mat_cloth_teal.tres       # Indian teal / indigo fabric
│       ├── mat_brass.tres            # Polished village brass & copper
│       └── mat_energy_glow.tres      # Projectile emission material
│
└── tests/
    ├── test_runner.gd                # Automated headless test suite
    └── test_runner.tscn              # Headless test scene
```

---

## 🚀 How to Run

### In the Godot Editor
1. Open **Godot 4.x** (v4.0 or newer).
2. Click **Import** and select the `project.godot` file in this directory.
3. Click **Open & Edit**.
4. Press `F5` (or click the Play button in the top right) to run `res://scenes/main.tscn`.

### Controls
| Action | Mobile Touch | Desktop / PC |
|---|---|---|
| **Move** | Drag **Left Virtual Joystick** | `W`, `A`, `S`, `D` or Arrow Keys |
| **Look / Rotate Camera** | Drag finger on **Right side of screen** | Right-click Drag or Alt + Left-click Drag |
| **Fire Projectile** | Tap **Fire Button** (Bottom-Right) | `Spacebar` or Left-click Fire Button |
| **Help Overlay** | Tap **❓ Controls** button (Top-Right) | Click **❓ Controls** button |

---

## 📱 Exporting to Mobile (Android & iOS)

### Android
1. Go to **Project > Export...**
2. Add an **Android** preset.
3. Ensure Android SDK / Build Tools are configured in Editor Settings.
4. Set **Rendering Method** to `Mobile` (Vulkan) or `Compatibility` (OpenGL ES 3.0).
5. Click **Export Project** to generate the `.apk` or `.aab`.

### iOS
1. Go to **Project > Export...**
2. Add an **iOS** preset.
3. Set your Bundle Identifier and Team ID.
4. Click **Export Project** to produce the Xcode project.

---

## 🧪 Running Automated Tests
To run the automated headless verification suite:
```bash
godot --headless --scene res://tests/test_runner.tscn
```
Expected output:
```
=== Running Mobile 3D Test Suite ===
✓ Nodes loaded and entered tree
✓ Player moving, velocity: (0.0, 0.0, -0.466667)
✓ Camera rotated from 0.000000 to -0.218166
✓ Fire button triggered projectile
✓ Pot broken status: true
=== ALL TESTS PASSED SUCCESSFULLY ===
```

---

## 📄 License
MIT License. All assets, scripts, and scenes are free to use, modify, and distribute.
