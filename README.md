MatchaNovel
==========

## A visual novel engine.

For an example, try the web demo: [https://halfstar.itch.io/matchanovel](https://halfstar.itch.io/matchanovel)

![screenshot](/docs/images/screenshot_1.jpg)

---

## What is MatchaNovel?
MatchaNovel is an open source multiplatform engine for narrative works, like visual novels and adventure games. 
It can be integrated with the [Defold](https://defold.com/) game engine or other Lua based engines, to use narrative features like a writer friendly scripting system and automatic textboxes in other genres as well.

It consists of these parts:

- **MatchaScript:** a Lua based scripting language for narrative works, that can be imported into an engine

- **MatchaNovel:** a Lua backend for visual novels that extends MatchaScript, and allows renpy-like scripting

- **MatchaNovel for Defold:** a library and GUI for the open source 2D+3D game engine Defold

- **Jasmine:** a textbox library for Defold

Currently working fully on these platforms: **Windows**, **Linux**, **macOS**, **Android**, **iOS**, **HTML5**

Platforms it can export to, but I could not test yet without a devkit: **Nintendo Switch**

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
- by opening the [empty template project](https://github.com/HalfstarDev/matchanovel/releases/download/v0.2.0/MatchaNovel.Empty.Defold.project.English.zip) in Defold **(recommended for releasing a visual novel)**
- (There is also a [seperate template that includes Japanese fonts](https://github.com/HalfstarDev/matchanovel/releases/download/v0.2.0/MatchaNovel.Empty.Defold.project.Japanese.zip), which are not in the English version to keep the file size down.)
- or by downloading the [standalone reader](https://github.com/HalfstarDev/matchanovel/releases/download/v0.2.0/MatchaNovel.Reader.demo.Windows.zip) and editing the script and asset files **(recommended for quick prototyping without advanced features)**
- or by importing the [library](https://github.com/HalfstarDev/matchanovel/archive/refs/tags/v0.2.0.zip) in Defold or another Lua based engine **(recommended for integrating into a larger non-VN game)**

If you import the MatchaNovel library into an existing Defold project, you should also install the [DefOS](https://github.com/subsoap/defos) library, so that the fullscreen setting will work.

---

## How to use:
You can play a project by pressing `Project -> Build (Ctrl+B)` in Defold, or by starting `matchanovel.exe` in the reader project.

Your assets should be put into the folders in `/assets`. The most important is the script, which contains your text and logic.

Let's try our first script. Write this line in `assets/scripts/script.txt`:

```
Hello World!
```
That's enough for a hello world program. If you start the project, it will repeat the text you wrote in the script. 
This works because any text that is not recognized as another valid action will be used as "say" action, and printed to the textbox.

### Label and jump:
Now some more actions:
```
label start
```
This defines the current line as the label called `start`. The label name can be any name valid as Lua variable, so it should start with a letter, and consist only of letters, numbers and underscores. 
The label `start` is a special label, this is where the script will start when starting a new game.

To jump to a label, use
```
jump label_name
```

### Speak:
If you want a text to be spoken by a specific character, use a colon:
```
Alice: Hello.
```

The name before the colon will be displayed above the text. If you don't want to write out the full name every time, you can assign a character to a variable, like this:
```lua
a.name = "Alice"
a: Hello.
a: How are you?
```

Line breaks will be added automatically according to the size of the text and the box. You can also add manual line breaks by using `\n`.
```
First line\nSecond line
```

If you want for example "jump" to be spoken, but not by a character, you can't just write
```
jump
```
as that's a keyword already. But you could write
```
: jump
```
to explicitly let it be a say command, but without a speaker.


### Variables:
In general, the line
```lua
x = z
```
will set the variable named `x` to `z`, and
```lua
x.y = z
```
will set the property `y` of the object `x` to `z`.

Variables can also be used directly in text, by putting them in curly brackets:
```
a: My name is {a.name}.
```

If you need a string capitalized, just write the name capitalized when calling it.
```lua
abc = "test"
a: {abc} {Abc} {ABC}.
```
will be displayed as:

> Alice: test Test TEST.

You can use Lua expessions to set a variable:
```
a = 1 + 2
b = a^2 * math.random(2, 10) + (a % 2)
c = d or a
```

You can even use Lua expressions in curly brackets:
```
a: 97 * 63 + x = {97 * 63 + x}.
a: Random number from 1 to 100: {math.random(1,100)}.
a: You are running this demo on {system.name}.
a: Is x larger than or equal to 9? {x >= 9 and "Yes" or "No"}.
a: Turn all vowels into stars: {string.gsub("Turn all vowels into stars", "[AEIOUaeiou]", "*")}
```

Additionally there are some operators that MatchNovel has that are not part of standard Lua:
```lua
a++          -- same as a = a + 1
a += 2       -- same as a = a + 2
a -= 1       -- same as a = a - 1
a *= 4       -- same as a = a * 4
a /= 2       -- same as a = a / 2
a %= 3       -- same as a = a % 3  (modulo)
a ..= "two"  -- same as a = a .. "two"  (string concatenation)
```
Note that unlike similar operators in other languages, these will also work if the first variable is not yet defined. 
Using `a += 2` when `a == nil`, will result in `a` being treated as being `0`, so after the operator it will end up with `a = 2`. 
So if you want to create a flag and set it to true, using `flag++` is functionally the same as `flag = true`, although slightly less efficent, using a number instead of a boolean. 

Also note that `a++` is a whole action taking its own line, and can not be used inside other expressions, and does not have variations. 
There is NO `a = b++`, or `++a`, or `a--`, or `--a`, as these would clash with standard Lua syntax. 
It's a shortcut to increase a variable by one, and that's all.

### Sprites:
#### Show:
To show a sprite for a character, use
```lua
a.sprite = "alice.png"
show a
```
where `a.sprite` must be either a file in `/assets/images/sprites`, or the path from your project folder to the file, like
```lua
a.sprite = "/custom_folder/spr/a01.png"
```
Note that any folder outside of `/assets` that you use this way must be added to Custom Resources in your `game.project` file.

If you don't specify a position, the character will be automatically positioned, see section [Automatic sprite positioning](https://github.com/HalfstarDev/matchanovel#automatic-sprite-positioning).

To define a position, define a variable with properties x and y:
```lua
pos_right.x = 0.75
pos_right.y = 0

show a at=pos_right
```
The units of x and y are fractions of the screen size. So the position x=0 is at the left of the screen, x=1 at the right, x=0.5 at the center, and x=0.75 between center and right. y=0 is the bottom, y=1 the top, and so on. 
You can also use numbers smaller than 0 or larger than 1, so for example y=-0.5 would start a half screen height below the bottom.

You can even set a scale to a position. Sprites that are shown on that position will be scaled with the factor of that position. So a character with scale `1.2` on a position with scale `0.5` will be shown with a scale of `0.6`.
```lua
pos_back.x = 0.3
pos_back.y = 0.2
pos_back.scale = 0.5

show a at=pos_back
```

If you don't want a character to appear instantly, you can also use transitions, like
```lua
show a transition=fade
show a transition=move_up
show a transition=grow duration=0.5
```
where `transition` is the name of the transition you would like to use, and `duration` the time the transition will use in seconds. If no duration is given, the default value will be used.

By default, a new character will be shown in front of all previous characters. You can also specify to shown them in front of a certain character, below a character, at the back, or at the front:
```
show a above=b
show a below=b
show a above=back
show a below=front
``` 

You can also change the default arguments for show. If you want all characters to fade in with a duration of 1.2 seconds and added to the back instead of the front, as long as no other values are used, you can do this:
```lua
show.transition = "fade"
show.duration = 1.2
show.above = "back"
```

#### Hide:
To hide a character again, use:
```lua
hide a
```

You can also hide all characters at once:
```lua
hide all
```

You can again use transitions for this, or the value `to` to give a vector to move in, like:
```lua
hide a transition=instant
hide a transition=fade
hide a transition=move_down duration=1
hide a transition=shrink
pos_down.y = -0.5
hide a to=pos_down
```


#### Move:
You can also move a shown sprite to a new position:

```lua
move a to=left
```

Like with `show`, you can also move a character above or below another character (or the front, or the back). You don't have to specify a `to` value, without it the sprite will stay in place, and just change the order.
```lua
move a above=b
```

For movement animations, you can also change the easing:
```lua
move a to=left easing=INOUTSINE
```

The default easing if none is specified is INOUTSINE.
There are the following easing types:
LINEAR, INBACK, EASING_OUTBACK, INOUTBACK, OUTINBACK, INBOUNCE, OUTBOUNCE, INOUTBOUNCE, OUTINBOUNCE, INELASTIC, OUTELASTIC, INOUTELASTIC, OUTINELASTIC, INSINE, OUTSINE, INOUTSINE, OUTINSINE, INEXPO, OUTEXPO, INOUTEXPO, 
OUTINEXPO, INCIRC, OUTCIRC, INOUTCIRC, OUTINCIRC, INQUAD, OUTQUAD, INOUTQUAD, OUTINQUAD, INCUBIC, OUTCUBIC, INOUTCUBIC, OUTINCUBIC, INQUART, OUTQUART, INOUTQUART, OUTINQUART, INQUINT, OUTQUINT, INOUTQUINT, OUTINQUINT. 
For details on how those easings work, see the [MatchaNovel demo](https://halfstar.itch.io/matchanovel), or the [Defold manual](https://defold.com/manuals/property-animation/).

#### Flip:
You can flip a sprite horizontally with the flip action. By default, it will show a rotation on the z axis with a duration of 1 second, but you can also change the duration.
```
flip alice
flip alice duration=0.5
flip alice duration=0.0
```

If instead of a flip animation, you want to show a sprite flipped in the first place, you set the values `flip_x` or `flip_y` directly before showing it.
```
alice.flip_x = true
alice.flip_y = false
show alice
```

### Automatic sprite positioning:
You can change at which position a new sprite without a position will be placed.
By default, they will be put at the highest number, so if there are 3 automatically positioned sprites already, the new one will be placed at position 4.
If you want it at another position, use a number as position argument. For example, if you want the fourth new sprite to be put at position 3, and the old 3 at 4, use:
```
show alice at=3 
```

You can customize the rules for automatic sprite positioning.

To set the width of screen that the sprites are spread on, use `sprites.auto_n.width`, with `n` being the total number of sprites, and the width 1.0 being the whole width of the screen.
```lua
sprites.auto_2.width = 0.4
sprites.auto_3.width = 0.6
sprites.auto_4.width = 0.75
sprites.auto_5.width = 0.9
```

You can also set the positions individually using `sprites.auto_i_n`, with `n` being the total number of sprites, and i the number of the individual sprite.
```lua
sprites.auto_1_1.x = 0.5
sprites.auto_1_1.y = 0.1

sprites.auto_1_2.x = 0.25
sprites.auto_1_2.y = 0.1

sprites.auto_2_2.x = 0.75
sprites.auto_2_2.y = 0.1
```

The duration of the automatic ordering of sprites if set by the variable `sprites.auto.duration`:
```
sprites.auto.duration = 1
```

### Expressions:
To change the image of a shown character, you can just change its sprite variable. This will change the sprite immediately and permanently.
```lua
alice.sprite = "alice_happy.png".
```

To make changing sprites easier, the expression system exists. You can manually define expressions with different sprites.
```lua 
alice.sad.sprite = "alice_sad.png"
```

If you now call that expression with `alice.sad`, the character `alice` will change its expression to `sad`, which means it will change its sprite to `alice_sad.png`.
```lua 
alice.sad
```

If an expression is used in its own line, it will stay until changed again.
You can also use an expression on the speaker of a "say" line. In this case, the sprite will change as well, but only for this one line. So the next line it will revert again.
```lua
alice.sad: Now I am sad.
```

The pattern of the filename in the example above, `charactername_expressionname.png`, will be used by default if you call an expression that you have not defined. So even without a manual definition, you can just use
```lua
alice.angry
```
as long as the file `/assets/images/sprites/alice_angry.png` exists.

### Scenes:
To show a background scene, either use a filename:
```lua
scene room.jpg
```
or a scene name:
```lua
room.image = "room.jpg"
scene room
```

The scene name follows similar rules as sprites, but with the default folder for filenames without a path being `/assets/images/background`.

You can again use the same syntax for transitions and their duration:

```lua
scene room transition=instant
scene room transition=fade duration=1.5
scene room transition=fade_to_black
scene room transition=shrink
scene room transition=grow
scene room transition=grow_horizontal
scene room transition=grow_vertical
scene room transition=zoom_out
scene room transition=zoom_in
scene room transition=slide_horizontal
scene room transition=slide_horizontal_reverse
scene room transition=slide_vertical
scene room transition=slide_vertical_reverse
```

You can also change the default transition and duration, so you don't have to change it to the same values every time.
```lua
scene.transition = "fade"
scene.duration = 0.5
```

A new argument is `color`, which can be used to change the tint of the image. 
```lua
scene room color=red
```
This will tint the image red. For colors you can either use HTML names, hex colors, or variables with RGB values (from 0 to 1). These will all do the same:
```lua
scene room color=cyan

scene room color=#00FFFF

custom_cyan.r = 0.0
custom_cyan.g = 1.0
custom_cyan.b = 1.0
scene room color=custom_cyan
```
You can also use a color instead of an image file to create a solid color background, like
```
scene DeepSkyBlue
```
Furthermore, you can use the argument `transition_color` to change the color of a transition (if it has any), like:
```
scene green transition=fade_to_black transition_color=red
```

### If:
You can add branches based on the value of a variable, with if, else, and elseif:
```
if strength > 9000 or found_key
  You opened the door.
  open = true
  jump door_opened
elseif strength > 7000
  The door moved a little bit, but you didn't get it to open.
else
  You can't open the door at all.
  
As you couldn't open the door, you left the room.
```

If the expression after if is true, then the action block starting in the next line will be started, even if it is indented. Usually, deeper indented lines will be ignored. Only ifs, jumps and choices can access them.

If at the end of the action block you did not jump out of it, you will jump to the next line with a lower indention. 
For longer branches, it is recommended to use jumps to the base line instead of having a big tree-like indention structure.

You can use Lua expressions in the `if` statement. Some useful operators:

Logical: `and`, `or`, `not`

Relational: `==`, `~=`, `<`, `>`, `<=`, `>=`

Arithmetic: `+`, `-`, `*`, `/`, `^`, `%`

### Choices:
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

You can also use variable expressions and line breaks like in say commands in the choice text:
```
Who are you?
> My name is {a.name}.
  jump answer_1
> I won't tell you.
  jump answer_2

What will you do next?
> Read a book\n(Knowledge + 1)
  knowledge += 1
  You read a book. This increased your knowledge.
> Go jogging\n(Stamina + 2)
  stamina += 2
  You went jogging. This increased your stamina.
```

### Random:
To get a random result, you can use the standard math library from Lua.

If you want a random real number in the range `[0,1)`, you can call `math.random()` without an argument:
```
Your chance to win the lottery is 2%.
if math.random() <= 0.02
  You won.
else
  You lost.
```

To get an integer in the range `[1, n]`, call `math.random(n)`:
```
dice = math.random(6)
You rollled a {dice}.
if dice > 2
  You hit the enemy with your fireball.
else
  You missed the enemy.
```

### Comments:
Comments are denoted with `--`, as usual in Lua. You can use those to structure your script and leave annotations.

### Particles:
You can create particle effects in the Defold editor. More on that will be explained in an advanced manual soon. Some particle effects are already predefined with scene.weather.
```lua
scene.weather = "none"
scene.weather = "rain"
scene.weather = "snow"
scene.weather = "blizzard"
scene.weather = "fireflies"
scene.weather = "clear"
```

### Music and sound:
To play music, you have to first add the file to the `sound.go` game object in Defold. Clone the `bgm` or `sfx` component, depending on if you need a background music or sound effect. Then change the sound property. 
You can also change gain, pan, and speed for each file. Make sure that looping is checked if you want the file to repeat until it is stopped.

You can play music and sound with:
```
play music bgm_name
play sound sfx_name
```

Background music will play until another music is played, or until you stop it manually:
```
stop music
```

### Return to title:
To return to the title, simply use `title`.
```
What will you do?
> Run away
  You escaped.
  jump chapter_2
> Talk to the monster
  You died.
  GAME OVER
  title
```

### Using multiple script files:
To add more script files (like `chapter_1.txt`, `chapter_2.txt`, etc.), add the name of the new files to `scripts.txt`. Labels are global, so you can use `jump` to jump to other scripts.

### Print to console:
If you are running your project from Defold or a debug build with a console, you can print text to the console, using the same syntax as say.
```
debug.print Starting timer.
a = system.os_clock
Click to continue.
b = system.os_clock
debug.print The message was displayed for {b - a} seconds.
```

### Pronouns:
MatchaNovel can be extended with Lua modules. As an example, a preinstalled pronoun system is implemented as a Lua extension. To set pronouns, simply use
```lua
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

### FMOD:

The FMOD library is not preinstalled in the open source version of MatchaNovel,
but you can either install the library in your Defold project yourself (see next section),
or use the [FMOD template project](https://github.com/HalfstarDev/matchanovel/releases/download/v0.2.0/MatchaNovel.FMOD.template.zip) with preinstalled FMOD.

To use a FMOD bank, copy the `.bank` files into the folder `/assets/audio/fmod`.

The bank `Master.bank` (including `Master.strings.bank`) will be loaded automatically. If you want to load more banks on start, set their names (without extension) as `fmod.bank_*` in the init script:
```
fmod.bank_1 = "My_bank"
fmod.bank_2 = "My_bank.strings"
fmod.bank_3 = "Another_bank"
fmod.bank_4 = "Another_bank.strings"
```

To start an FMOD event from the Master bank, use the `fmod play` action:
```
fmod play sound event_name 
```
If the event is in another bank than the Master bank, then use the argument fmod_bank:
```
fmod play sound car fmod_bank=vehicles 
```
For 3D events, you can also use the `source` command as for regular MatchaNovel sounds to use the position of a sprite as sound source:
```
fmod play sound shout_alice source=alice 
```

### Installing FMOD:

Only if you don't use the FMOD template, but want to add MatchaNovel to an existing Defold project, you have to install FMOD before you can use it.

See https://github.com/dapetcu21/defold-fmod for the newest release, like https://github.com/dapetcu21/defold-fmod/archive/v2.6.1.zip. 

Either copy the fmod folder into your project, or use it as an dependency in your `game.project` file and fetch it.

To set a speaker mode, add this to your `game.project` file, and change the speaker mode to your preference:
```
[fmod]
speaker_mode = stereo
```

To run your project directly from the Defold editor, you also have to copy `fmod/res` into your project, and put the path into `game.project`:
```
[fmod]
lib_path = fmod/res
```

### More Actions:

#### Exit:
You can close the whole application with the `system.exit` action.
```
The game will close now.
system.exit
```

#### Stop skipping:

To manually stop the skipping function on a certain line, use `skip.stop`.
```
skip.stop
```

#### Open URLs:

To open an URL, use `system.open_url`.
```
system.open_url www.google.com
system.open_url C:\some\folder
system.open_url save.folder
```

#### Change window title:

You can set the title of the window on boot in the `game.project` file.
```
[project]
title = My Visual Novel
```

To change the title of the window in the script at any time, set the variable `system.window_title`.
```
system.window_title = "This is now the new window title"
```

### Variables:
There are some variables that MatchaNovel provides automatically:

| Name                  | Values                                                                                        | Description                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| system.name           | String: `"Windows"`, `"Linux"`, `"Darwin"`, `"Android"`, `"iPhone OS"`, `"HTML5"`, `"Switch"` | The currently used operating system.                                                                |
| system.is_windows     | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is Windows.                                           |
| system.is_linux       | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is Linux.                                             |
| system.is_macos       | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is Mac OS.                                            |
| system.is_android     | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is Android.                                           |
| system.is_ios         | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is iPhone OS.                                         |
| system.is_html        | Boolean: `true`, `false`                                                                      | `true` if running in a browser.                                                                     |
| system.is_switch      | Boolean: `true`, `false`                                                                      | `true` if running on a Nintendo Switch.                                                             |
| system.is_mobile      | Boolean: `true`, `false`                                                                      | `true` if the currently used operating system is Android or iPhone OS (but not for HTML on mobile). |
| system.language       | String: `"en"`, `"fr"`, `"de"`, ...                                                           | The current system language.                                                                        |
| system.is_debug       | Boolean: `true`, `false`                                                                      | `true` if the project is running in debug mode.                                                     |
| system.engine_version | String: `"1.4.8"`, `"1.4.7"`, ...                                                             | The current engine version of Defold.                                                               |
|                       |                                                                                               |                                                                                                     |
| system.time           | Number: `1689370000`, etc.                                                                    | The current Unix time (in whole seconds).                                                           |
| system.time_string    | String: `"2022-12-31 23:59:30"`, ...                                                          | The current date and time as readable string, in the format `YYYY-MM-DD HH:MM:SS`.                  |
| system.time_date      | String: `"2022-12-31"`, ...                                                                   | The current date as readable string, in the format `YYYY-MM-DD`.                                    |
| system.time_clock     | String: `"23:59:30"`, ...                                                                     | The current time as readable string, in the format `HH:MM:SS`.                                      |
| system.time_year      | String: `"2022"`, ...                                                                         | The current year.                                                                                   |
| system.time_month     | String: `"01"`, `"02"`, `"03"`, ..., `"12"`                                                   | The current month as string, with `01` being January.                                               |
| system.time_day       | String: `"01"`, `"02"`, `"03"`, ..., `"31"`                                                   | The current day of the month.                                                                       |
| system.time_hour      | String: `"00"`, `"01"`, `"02"`, ..., `"23"`                                                   | The current hour.                                                                                   |
| system.time_minute    | String: `"00"`, `"01"`, `"02"`, ..., `"59"`                                                   | The current minute.                                                                                 |
| system.time_second    | String: `"00"`, `"01"`, `"02"`, ..., `"59"`                                                   | The current second.                                                                                 |
| system.time_weekday   | String: `"1"`, `"2"`, `"3"`, `"4"`, `"5"`, `"6"`, `"7"`                                       | The current weekday, with `1` being monday, and `7` being sunday.                                   |
| system.time_hour12    | String: `"01"`, `"02"`, `"03"`, ..., `"12"`                                                   | The current hour in the 12-hour clock convention.                                                   |
| system.time_ampm      | String: `"a.m."`, `"p.m".`                                                                    | The current time period, "a.m." before midday, "p.m." after midday.                                 |
| system.os_clock       | Number: `0.001`, `1.002`, `9876.000`, ...                                                     | The current CPU time used by the executable (in seconds).                                           |
|                       |                                                                                               |                                                                                                     |
| settings.text_speed   | Number: `0`, ..., `100`                                                                       | The current text speed setting.                                                                     |
| settings.auto_speed   | Number: `0`, ..., `100`                                                                       | The current auto text speed setting.                                                                |
| settings.volume_music | Number: `0`, ..., `100`                                                                       | The current music volume setting.                                                                   |
| settings.volume_sound | Number: `0`, ..., `100`                                                                       | The current sound volume setting.                                                                   |
| settings.font         | String: `"sans"`, `"serif"`, ...                                                              | The current font setting.                                                                           |
| settings.fullscreen   | Boolean: `true`, `false`                                                                      | The current fullscreen setting. `true` if fullscreen.                                               |
| settings.skip_all     | Boolean: `true`, `false`                                                                      | The current skip setting. `true` if skipping all text, `false` if only read text.                   |
| settings.lock         | Boolean: `true`, `false`                                                                      | The current quickmenu lock setting. `true` if locked.                                               |
|                       |                                                                                               |                                                                                                     |
| save.folder           | String: `"C:\Users\MyName\AppData\Roaming\MyGame\"`, ...                                      | The save folder path.                                                                               |
|                       |                                                                                               |                                                                                                     |
| sprites.scale         | Number: `1.0`, `2.5`, `0.8`, ...                                                              | The global scale of all sprites.                                                                    |
|                       |                                                                                               |                                                                                                     |
| audio.volume          | Number: `0.0`, ..., `1.0`                                                                     | The master volume, applied to music, sounds, and voices. Multiplies with user settings.             |
| music.volume          | Number: `0.0`, ..., `1.0`                                                                     | The volume applied to music only. Multiplies with user settings and `audio.volume`.                 |
| sound.volume          | Number: `0.0`, ..., `1.0`                                                                     | The volume applied to sound only. Multiplies with user settings and `audio.volume`.                 |
|                       |                                                                                               |                                                                                                     |
| skip.all              | Boolean: `true`, `false`                                                                      | Overwrites `settings.skip_all` if `true`. If `false`, behaviour depends on setting.                 |
|                       |                                                                                               |                                                                                                     |
| show.transition       | String: `fade`, `instant`, ...                                                                | The default transition type for the action `show`, if used without a `transition` argument.         |
| show.duration         | Number: `0.5`, `0`, `2.0`, ...                                                                | The default duration for the action `show`, if used without a `duration` argument.                  |
| show.easing           | String: `"INOUTSINE"`, `"LINEAR"`, ...                                                        | The default easing type for the action `show`, if used without an `easing` argument.                |
| hide.transition       | String: `fade`, `instant`, ...                                                                | The default transition type for the action `hide`, if used without a `transition` argument.         |
| hide.duration         | Number: `0.5`, `0`, `2.0`, ...                                                                | The default duration for the action `hide`, if used without a `duration` argument.                  |
| hide.easing           | String: `"INOUTSINE"`, `"LINEAR"`, ...                                                        | The default easing type for the action `hide`, if used without an `easing` argument.                |
| move.duration         | Number: `0.5`, `0`, `2.0`, ...                                                                | The default duration for the action `move`, if used without a `duration` argument.                  |
| move.easing           | String: `"INOUTSINE"`, `"LINEAR"`, ...                                                        | The default easing type for the action `move`, if used without an `easing` argument.                |
| flip.duration         | Number: `0.5`, `0`, `2.0`, ...                                                                | The default duration for the action `flip`, if used without a `duration` argument.                  |
|                       |                                                                                               |                                                                                                     |
| loremipsum            | String: `"Lorem ipsum dolor sit amet, consetetur sadipscing elitr"...`                        | An example text of length 36 words. Can be used to fill a textbox without typing a lot.             |


As other variables, these can be used in text, or as an argument in other actions:
```
alice: The current time is {system.time_clock}.

if system.name == "Linux"
  You are using Linux.
```

But keep in mind that variables from `system.time_*` that represent numbers are actually strings, so you either have to compare them to strings, or convert them to numbers.
```
if system.time_month == 1
  It is January.
  -- This will not work, even if it is January, because "01" does not equal 1.
  
if system.time_month == "01"
  It is January.
  -- This will work.
  
if tonumber(system.time_month) == 1
  It is January.
  -- This will work as well.
  
if system.time_month + 1 == 2
  Next month is February.
  -- Even this works, because Lua can add a number to a string of a number, and will return a number.
```

---

## More
I will add manuals for advanced features soon:
- How to edit the GUI
- Creating custom commands
- Bundle distribution
- Packing atlas files

For more questions, you can ask on the [official Discord channel](https://discord.gg/uUtEVtr9tm).

---

## Roadmap
Features currently in work:
- More animation options
- More text formatting options
- Multiple text boxes
- Different log types
- CG and music gallery
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
Because this is still in early development, I will change much of the code base frequently, so pull requests don't make much sense at this point. 
(Although you are free to experiment with the code however you like, it's open source).

If you want to help right now, either creating small projects with MatchaNovel, or adding useful features to the [Defold](https://github.com/defold/defold) engine would be best. 

Or donate on [GitHub Sponsor](https://github.com/sponsors/HalfstarDev).

---
