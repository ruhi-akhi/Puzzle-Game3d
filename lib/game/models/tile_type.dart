/// All tile types supported in Echo Labyrinth.
enum TileType {
  empty,
  wall,
  floor,
  player,
  door,
  doorOpen,
  key,
  box,
  goal,
  mirror,
  mirrorSlash,
  mirrorBackslash,
  laserEmitter,
  laserBeam,
  redSwitch,
  blueSwitch,
  redDoor,
  blueDoor,
  teleporterA,
  teleporterB,
  ice,
  bomb,
  cloneSpawn,
  timeSwitch,
  gravityPad,
  darkZone,
  lightZone,
}

extension TileTypeExt on TileType {
  bool get isSolid {
    switch (this) {
      case TileType.wall:
      case TileType.box:
      case TileType.door:
      case TileType.redDoor:
      case TileType.blueDoor:
        return true;
      default:
        return false;
    }
  }

  bool get isWalkable {
    switch (this) {
      case TileType.wall:
      case TileType.box:
      case TileType.door:
      case TileType.redDoor:
      case TileType.blueDoor:
      case TileType.laserBeam:
        return false;
      default:
        return true;
    }
  }

  bool get isPushable => this == TileType.box || this == TileType.bomb;

  String get label {
    switch (this) {
      case TileType.wall:
        return '#';
      case TileType.floor:
        return '.';
      case TileType.player:
        return '@';
      case TileType.door:
        return 'D';
      case TileType.doorOpen:
        return 'd';
      case TileType.key:
        return 'K';
      case TileType.box:
        return 'B';
      case TileType.goal:
        return 'G';
      case TileType.mirror:
        return 'M';
      case TileType.mirrorSlash:
        return '/';
      case TileType.mirrorBackslash:
        return '\\';
      case TileType.laserEmitter:
        return 'L';
      case TileType.redSwitch:
        return 'R';
      case TileType.blueSwitch:
        return 'S';
      case TileType.redDoor:
        return 'r';
      case TileType.blueDoor:
        return 's';
      case TileType.teleporterA:
        return 'T';
      case TileType.teleporterB:
        return 't';
      case TileType.ice:
        return 'I';
      case TileType.bomb:
        return '!';
      case TileType.cloneSpawn:
        return 'C';
      case TileType.timeSwitch:
        return 'X';
      case TileType.gravityPad:
        return 'g';
      case TileType.darkZone:
        return 'x';
      case TileType.lightZone:
        return 'o';
      default:
        return ' ';
    }
  }
}

TileType tileTypeFromChar(String c) {
  switch (c) {
    case '#':
      return TileType.wall;
    case '.':
      return TileType.floor;
    case '@':
      return TileType.player;
    case 'D':
      return TileType.door;
    case 'd':
      return TileType.doorOpen;
    case 'K':
      return TileType.key;
    case 'B':
      return TileType.box;
    case 'G':
      return TileType.goal;
    case 'M':
      return TileType.mirror;
    case '/':
      return TileType.mirrorSlash;
    case '\\':
      return TileType.mirrorBackslash;
    case 'L':
      return TileType.laserEmitter;
    case 'R':
      return TileType.redSwitch;
    case 'S':
      return TileType.blueSwitch;
    case 'r':
      return TileType.redDoor;
    case 's':
      return TileType.blueDoor;
    case 'T':
      return TileType.teleporterA;
    case 't':
      return TileType.teleporterB;
    case 'I':
      return TileType.ice;
    case '!':
      return TileType.bomb;
    case 'C':
      return TileType.cloneSpawn;
    case 'X':
      return TileType.timeSwitch;
    case 'g':
      return TileType.gravityPad;
    case 'x':
      return TileType.darkZone;
    case 'o':
      return TileType.lightZone;
    default:
      return TileType.empty;
  }
}

enum Direction { up, down, left, right }

extension DirectionExt on Direction {
  (int, int) get delta {
    switch (this) {
      case Direction.up:
        return (0, -1);
      case Direction.down:
        return (0, 1);
      case Direction.left:
        return (-1, 0);
      case Direction.right:
        return (1, 0);
    }
  }

  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }
}
