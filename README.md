# MatchaNovel
## A visual novel engine.

For an example, try the web demo: [https://halfstar.itch.io/matchanovel](https://halfstar.itch.io/matchanovel)

![screenshot](/docs/images/screenshot_1.jpg)

---

## What is MatchaNovel?
MatchaNovel is an open source multiplatform engine for narrative works, like visual novels and adventure games. It can be integrated with the Defold game engine or other Lua based engines, to use narrative features like a writer friendly scripting system and automatic textboxes in other genres as well.

It consists of these parts:

- **MatchaScript:** a Lua based scripting language for narrative works, that can be imported into an engine

- **MatchaNovel:** a Lua backend for visual novels that extends MatchaScript, and allows renpy-like scripting

- **MatchaNovel for Defold:** a library and GUI for the open source 2D+3D game engine Defold

- **Jasmine:** a textbox library for Defold

Currently working fully on these platforms: **Windows**, **Linux**, **macOS**, **Android**, **HTML5**

Platforms it can export to, but I could not test yet without a devkit: **iOS** and **Nintendo Switch**

---

## Some key features:
- writer friendly scripting language
- you can make a full release with only MatchaScript code, or you can use Defold to edit the GUI and scenes in a WYSIWYG editor
- strong math and logic support by using Lua expressions and math libraries in the script, or import full Lua files as extensions
- Spine support
- FMOD support
- particle effects
- inbuilt pronoun system
- make your own syntax by changing the MatchaScript definitions
- can be used as dialogue system in a full Defold game, or use mini games made in Defold in your visual novel
- small build size: less than 5 MB, plus your assets
---

## How to install:
You can use MatchaNovel either:
- by opening the empty template project in Defold **(recommended for releasing a visual novel)**
- or by downloading the standalone reader and editing the script and asset files **(recommended for quick prototyping without advanced features)**
- or by importing the library in Defold or another Lua based engine **(recommended for integrating into a larger non-VN game)**

To import as a library, add https://github.com/HalfstarDev/matchanovel/archive/refs/tags/test2.zip to the dependencies in your game.project file.
---

## How to use:
You can play a project by pressing `Project -> Build (Ctrl+B)` in Defold, or by starting `matchanovel.exe` in the reader project.

Your assets should be put into the folders in `/assets`. The most important is the script, which contains your text and logic.

Let's try our first script. Write this line in `assets/scripts/script.txt`:

```
Hello World!
```
That's enough for a hello world program. If you start the project, it will repeat the text you wrote in the script. This works because any text that is not recognized as another valid action will be used as "say" action, and printed to the textbox.

Now some more actions:
```
label start
```
This defines the current line as the label called `start`. The label name can be any name valid as Lua variable, so it should start with a letter, and consist only of letters, numbers and underscores. The label `start` is a special label, this is where the script will start when starting a new game.

To jump to a label, use
```
jump label_name
```

If you want a text to be spoken by a specific character, use a colon:
```
Alice: Hello.
```

The name before the colon will be displayed above the text. If you don't want to write out the full name every time, you can assign a character to a variable, like this:
```
a.name = "Alice"
a: Hello.
a: How are you?
```

In general, the line
```lua
x = z
```
will set the variable named `x` to `z`, and
```lua
x.y = z
```
will set the property `y` of the object `x` to `z`.

Variables can also be used directly in text, by putting it in curly brackets:
```
a: My name is {a.name}.
```

If you need a string capitalized, just write the name capitalized when calling it.
```
abc = "test"
a: {abc} {Abc} {ABC}.
```
will be displayed as:

> Alice: test Test TEST.

You can even use Lua expressions in curly brackets:
```
a: 97 * 63 + x = {97 * 63 + x}.
a: Random number from 1 to 100: {math.random(1,100)}.
a: You are running this demo on {system.name}.
a: Is x larger than or equal to 9? {x >= 9 and "Yes" or "No"}.
a: Turn all vowels in this sentence into stars: {string.gsub("Turn all vowels in this sentence into stars", "[AEIOUaeiou]", "*")}
```

###Sprites:
To show a sprite for a character, use
```
a.sprite = "alice.png"
show a
```
where `a.sprite` must be either a file in `\assets\images\sprites`, or the path from your project folder to the file, like
```
a.sprite = "/custom_folder/spr/a01.png"
```
Note that any folder that you use this way must be added to Custom Resources in your `game.project` file.

If you don't specify a position, the character will appear in the center of the screen, starting from the bottom. To define and specify a position, use:
```
pos_a.x = 0.75
pos_a.y = 0
show a at = pos_a
```
The units of x and y are fractions of the screen size. So the position x=0 is at the left of the screen, x=1 at the right, x=0.5 at the center, and x=0.75 between center and right. y=0 is the bottom, y=1 the top, and so on. You can also use numbers smaller than 0 or larger than 1, so for example y=-0.5 would start a half screen height below the bottom.

If you don't want the character to appear instantly, you can also use transitions, like
```
show a transition = fade
show a transition = move_up
show a transition = grow duration = 0.5

```
where `transition` is the name of the transition you would like to use, and `duration` the time the transition will use in seconds. If no duration is given, the default value will be used.

To hide a character again, use:
```
hide a
```
You can again use transitions for this, or the value `to` to give a vector to move in, like:
```
hide a transition = instant
hide a transition = fade
hide a transition = move_down duration = 1
hide a transition = shrink
pos_down.y = -0.5
hide a to = pos_down

```

###Scenes:

To show a background scene, use:
```
scene room.jpg
```
The scene name follows the same rules as sprites, but with the default folder for filenames without a path being `\assets\images\background`.

You can again use the same syntax for transitions and their duration:

```
scene bg.jpg transition = instant
scene bg.jpg transition = fade duration = 1.5
scene bg.jpg transition = fade_to_black
scene bg.jpg transition = shrink
scene bg.jpg transition = grow
scene bg.jpg transition = grow_horizontal
scene bg.jpg transition = grow_vertical
scene bg.jpg transition = zoom_out
scene bg.jpg transition = zoom_in
scene bg.jpg transition = slide_horizontal
scene bg.jpg transition = slide_horizontal_reverse
scene bg.jpg transition = slide_vertical
scene bg.jpg transition = slide_vertical_reverse
```

You can also change the default transition and duration, so you don't have to change it to the same values every time.
```
scene.transition = "fade"
scene.duration = 0.5
```

A new argument is `color`, which can be used to change the tint of the image. 
```
scene bg.jpg color = red
```
This will tint the image red. For colors you can either use HTML names, hex colors, or variables with RGB values (from 0 to 1). These will all do the same:
```
scene bg.jpg color = cyan

scene bg.jpg color = #00FFFF

custom_cyan.r = 0.0
custom_cyan.g = 1.0
custom_cyan.b = 1.0
scene bg.jpg color = custom_cyan
```
You can also use a color instead of an image file to create a solid color background, like
```
scene DeepSkyBlue
```
Furthermore, you can use the argument `transition_color` to change the color of a transition (if it has any), like:
```
scene green transition = fade_to_black transition_color = red
```


###If:

You can add branches based on the value of a variable, like:
```
if strength > 9000
  You have enough strength to open the door.
  open = true
  jump door_opened
You can't open the door
  
```
If the expression after if is true, then the action block starting in the next line will be started, even if it is indented. Usually, deeper indented lines will be ignored. Only ifs, jumps and choices can access them.

If at the end of the action block you did not jump out of if, you will jump to the next line with a lower indention. For longer branches, it is recommended to use jumps to the base line instead of having a big tree-like indention structure.


###Choice:

This will give the reader a number of choices to pick, and execute a different branch according to the picked choice:
```
Where do you want to go?
> Go left.
  You went left.
  jump left
> Go right.
  You went right.
  jump right
> Go back.
  You went back.
  jump back
```
The structure works like with `if` again, with the difference that if you reach the end of the block without a jump, the rest of the choices will be ignored.


###Particles:
You can create particle effects in the Defold editor. More on that will be explained in an advanced manual soon. Some particle effects are already predefined with scene.weather.
```
scene.weather = "none"
scene.weather = "rain"
scene.weather = "snow"
scene.weather = "blizzard"
scene.weather = "fireflies"
scene.weather = "clear"
```

###Pronouns:
MatchaNovel can be extended with Lua modules. As an example, a preinstalled pronoun system is implemented as a Lua extension. To set pronouns, simply use
```
pronouns = "she"
pronouns = "he"
pronouns = "they"
```
These will set multiple useful variables, like this:
```
"Did {they} change {their} hair style? {They} look{verb_end} amazing now." "{THEY} {plural and "DO" or "DOES"}!"
```
will be displayed like this, if you chose 'she' as your pronouns:

> "Did she change her hair style? She looks amazing now." "SHE DOES!"

If you have variable pronouns for multiple characters, you can also link those to a name:
```
a.name = "Alice"
a.pronouns = "she"
b.name = "Bob"
b.pronouns = "he"

{a.name} prefers {a.they}, {b.name} prefers {b.they}.
```

> Alice prefers she, Bob prefers he.

###Music and sound:

To play music, you have to first add the file to the `sound.go` game object in Defold. Clone the `bgm` or `sfx` component, depending on if you need a background music or sound effect. Then change the sound property. You can also change gain, pan, and speed for each file. Make sure that looping is checked if you want the file to repeat until it is stopped.

You can play music and sound with:
```
play music bgm_name
play sound sfx_name
```

Background music will play until another music is played, or until you stop it manually:
```
stop music
```


###Comments:

Comments are denoted with `--`, as usual in Lua. You can use those to structure your script and leave annotations.


---
## More
I will add manuals for advanced features soon:
- How to edit the GUI
- Creating custom commands
- Bundle distribution
- Packing atlas files
- Many smaller actions

For more questions, you can ask on the [official Discord channel](https://discord.gg/uUtEVtr9tm).

---
## Roadmap
Features currently in work:
- More animation options
- More text formatting options
- Title menu options
- Multiple text boxes
- Different log types
- CG and music gallery
- Save thumbnails
- Map
- Gyro
- Auto character highlight
- Translation support
- Controller support

Future plans:
- Self voicing
- Flowcharts
- Mod support

Feel free to ask for more features.

---
## Support
Because this is still in early development, I will change much of the code base frequently, so pull requests don't make much sense at this point (although you are free to experiment with the code however you like, it's open source).

If you want to help right now, either creating small projects with MatchaNovel, or adding useful features to the Defold engine would be best. 


---

