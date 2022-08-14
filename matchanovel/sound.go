components {
  id: "sound"
  component: "/matchanovel/sound.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "bgm"
  type: "sound"
  data: "sound: \"/assets_internal/audio/bgm/bgm.ogg\"\n"
  "looping: 1\n"
  "group: \"bgm\"\n"
  "gain: 0.5\n"
  "pan: 0.0\n"
  "speed: 1.0\n"
  "loopcount: 0\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
