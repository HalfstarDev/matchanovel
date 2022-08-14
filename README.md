# matchanovel
A visual novel engine for Defold and other Lua based engines.

(This is an early preview, and does not contain a full documentation yet. I'll will update the manual and add missing features step by step.)

MatchaNovel is an open-source visual novel framework to create narrative games with the Defold engine, or another Lua based engine.

It consists of these parts:

MatchaScript: a Lua based scripting language for narrative works, that can be imported into an engine
MatchaNovel: a Lua backend for visual novels that extends MatchaScript, and allows renpy-like scripting
MatchaNovel for Defold: a library and GUI for the open source 2D+3D game engine Defold
Jasmine: my textbox library for Defold
Currently working fully on these platforms: Windows, Linux, macOS, Android, HTML5

Platforms it can export to, but I could not test yet without a devkit: iOS and Nintendo Switch

Some key features:

- writer friendly scripting language
- you can make a full release with only MatchaScript code, or you can use Defold to edit the GUI and scenes in a WYSIWYG editor
- strong math and logics support by using Lua expressions and math libraries in the script, or import full Lua files as extensions
- Spine support
- FMOD support
- particle effects
- inbuilt pronoun system
- make your own syntax by changing the MatchaScript definitions
- can be used as dialogue system in a full Defold game, or use mini games made in Defold in your visual novel
- small build size: less than 5 MB, plus your assets
