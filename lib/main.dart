import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const SquadUpApp());

// ───────────────────────── Constants ─────────────────────────
// Console-style dark palette: near-black background, charcoal surfaces, one blue accent.
Color get kBg => squadTheme.value == ThemeMode.dark ? const Color(0xFF0D0D0D) : const Color(0xFFF3F5F8);
Color get kCard => squadTheme.value == ThemeMode.dark ? const Color(0xFF1A1A1A) : Colors.white;
Color get kField => squadTheme.value == ThemeMode.dark ? const Color(0xFF242424) : const Color(0xFFECEFF3);
/// Hairline border used on cards and panels.
Color get kBorder => squadTheme.value == ThemeMode.dark ? const Color(0x1FFFFFFF) : const Color(0x1A000000);
const Color kAccent = Color(0xFF0070CC);
const Color kAccentLight = Color(0xFF3D9BFF); // accent for text/icons on near-black
const Color kTeal = Color(0xFF00439C); // deep blue partner colour for gradients
const Color kOnline = Color(0xFF2ECC71);
const Color kMuted = Color(0xFF8E8E93); // secondary text that reads on both dark and light
const kBrandGradient = LinearGradient(colors: [kTeal, kAccent]);
const kPlatforms = ['PlayStation', 'Xbox', 'Nintendo Switch', 'PC'];
const kRanks = ['Beginner', 'Casual', 'Intermediate', 'Advanced', 'Elite'];
const kAvail = ['Weekday evenings', 'Weekends', 'Late nights', 'Anytime'];
const kRegions = ['North America', 'South America', 'Europe', 'Asia', 'Oceania', 'Africa', 'Middle East'];
const kVis = ['Public', 'Friends Only', 'Private'];
const kGenders = ['Male', 'Female', 'Non-binary', 'Other', 'Prefer not to say'];
const kRatingLabels = ['Rarely / Occasionally', 'Sometimes / A few times a week', 'Often / Daily / Main game'];
const kNotes = [
  'Looking for a Pro Clubs squad',
  'Chill player, just for fun',
  'Grinding for rank up',
  'Down for casual co-op nights',
  'Learning the meta, be patient with me',
  'Competitive but friendly',
];
const kBios = [
  'Team player who loves clear comms. Always up for a late-night session.',
  'Here to meet people and win a few games. No toxicity, please.',
  'Competitive at heart, but I never rage quit. Looking for a regular squad.',
  'Casual gamer, big on co-op and good vibes.',
];
const kAvatars = [
  (Icons.sports_esports, Color(0xFF00C853)),
  (Icons.rocket_launch, Color(0xFF2962FF)),
  (Icons.bolt, Color(0xFFFFAB00)),
  (Icons.shield, Color(0xFF6A1B9A)),
  (Icons.local_fire_department, Color(0xFFD84315)),
  (Icons.pets, Color(0xFF00838F)),
  (Icons.smart_toy, Color(0xFF546E7A)),
  (Icons.diamond, Color(0xFFAD1457)),
  (Icons.sports_martial_arts, Color(0xFF558B2F)),
  (Icons.nightlight_round, Color(0xFF283593)),
];
const kCoverIcons = [Icons.sports_esports, Icons.sports_soccer, Icons.directions_car, Icons.castle, Icons.rocket_launch, Icons.gps_fixed];
const kCustom = 'Custom Game (Add Manually)';

/// Every game shown on the Games page: released titles first, then unreleased ones (see kUpcoming).
const kPopular = [
  'EA Sports FC 27', 'EA Sports FC 26', 'Call of Duty: Modern Warfare 4', 'Call of Duty: Warzone', 'Call of Duty: Black Ops 6',
  'Fortnite', 'Grand Theft Auto V', 'Apex Legends', 'Valorant', 'Rocket League', 'Minecraft', 'Overwatch 2',
  'Counter-Strike 2', 'League of Legends', 'Halo Infinite', 'Halo: Campaign Evolved', 'Destiny 2', 'Sea of Thieves',
  'Elden Ring', 'Black Myth: Wukong', 'God of War Ragnarök', 'Red Dead Redemption 2', 'Tekken 8', 'Street Fighter 6',
  'F1 25', 'F1 24', 'Genshin Impact', 'Roblox', 'Among Us', 'Fall Guys', 'Helldivers 2', 'Marvel Rivals',
  'The Legend of Zelda: Tears of the Kingdom', 'Pokémon Scarlet & Violet', 'Battlefield 6', 'Gears of War: E-Day',
  "Marvel's Wolverine", 'Control: Resonant', 'Phantom Blade Zero', 'Palworld', 'Madden NFL 27', 'Dota 2',
  'Rainbow Six Siege', 'PUBG: Battlegrounds', 'Rust', 'Warframe', 'Dead by Daylight', 'Lethal Company',
  'Stardew Valley', 'Terraria', 'Monster Hunter Wilds', 'Cyberpunk 2077', "Baldur's Gate 3", 'Forza Horizon 5',
  'Gran Turismo 7', 'Mario Kart 8 Deluxe', 'Super Smash Bros. Ultimate', 'Splatoon 3', 'Diablo IV', 'Path of Exile 2',
  // unreleased: find teammates before launch
  'Grand Theft Auto VI', 'Persona 4 Revival', 'Fable', 'Resident Evil: Veronica', 'The Witcher 4', 'Kingdom Hearts IV',
];

/// Unreleased games and their announced release (as of Nov 2026; dates can move).
const kUpcoming = {
  'Grand Theft Auto VI': 'Nov 19, 2026',
  'Persona 4 Revival': 'Feb 18, 2027',
  'Fable': 'Feb 23, 2027',
  'Resident Evil: Veronica': '2027',
  'The Witcher 4': 'TBA',
  'Kingdom Hearts IV': 'TBA',
};

/// Recent releases that get a NEW badge.
const kNew = {
  'EA Sports FC 27', 'Call of Duty: Modern Warfare 4', 'Gears of War: E-Day', "Marvel's Wolverine",
  'Control: Resonant', 'Phantom Blade Zero', 'Halo: Campaign Evolved', 'Madden NFL 27',
};

/// Steam store app IDs → real cover art from the Steam CDN. Everything else gets a generated cover (see GeneratedCover).
const kSteam = {
  'EA Sports FC 25': 2669320, 'Call of Duty: Warzone': 1938090, 'Call of Duty: Black Ops 6': 2933620,
  'Grand Theft Auto V': 271590, 'Apex Legends': 1172470, 'Rocket League': 252950, 'Overwatch 2': 2357570,
  'Counter-Strike 2': 730, 'Halo Infinite': 1240440, 'Destiny 2': 1085660, 'Sea of Thieves': 1172620,
  'Elden Ring': 1245620, 'Black Myth: Wukong': 2358720, 'God of War Ragnarök': 2322010,
  'Red Dead Redemption 2': 1174180, 'Tekken 8': 1778820, 'Street Fighter 6': 1364780, 'F1 24': 2488620,
  'F1 25': 3059520, 'Among Us': 945360, 'Fall Guys': 1097150, 'Helldivers 2': 553850, 'Marvel Rivals': 2767030,
  'Dota 2': 570, 'Rainbow Six Siege': 359550, 'PUBG: Battlegrounds': 578080, 'Rust': 252490, 'Warframe': 230410,
  'Dead by Daylight': 381210, 'Lethal Company': 1966720, 'Stardew Valley': 413150, 'Terraria': 105600,
  'Monster Hunter Wilds': 2246340, 'Cyberpunk 2077': 1091500, "Baldur's Gate 3": 1086940, 'Forza Horizon 5': 1551360,
  'Palworld': 1623730, 'Diablo IV': 2344520, 'Path of Exile 2': 2694490, 'Battlefield 6': 2807960,
};

/// Paste any direct image URL here to override or add a cover, e.g. 'Fortnite': 'https://…/fortnite.jpg'
const kCoverOverrides = <String, String>{};

/// Bundled cover art (assets/games/) for games with no Steam entry. Falls back to the generated gradient if the file fails to load.
const kCoverAssets = <String, String>{
  'Gears of War: E-Day': 'assets/games/gears_of_war_e_day.jpg',
  'Fable': 'assets/games/fable.jpg',
  'EA Sports FC 27': 'assets/games/ea_sports_fc_27.jpg',
  'EA Sports FC 26': 'assets/games/ea_sports_fc_26.jpg',
  'Call of Duty: Modern Warfare 4': 'assets/games/call_of_duty_modern_warfare_4.jpg',
  'Halo: Campaign Evolved': 'assets/games/halo_campaign_evolved.jpg',
  'Control: Resonant': 'assets/games/control_resonant.jpg',
  'Phantom Blade Zero': 'assets/games/phantom_blade_zero.jpg',
  'Madden NFL 27': 'assets/games/madden_nfl_27.jpg',
  'Persona 4 Revival': 'assets/games/persona_4_revival.jpg',
  'Resident Evil: Veronica': 'assets/games/resident_evil_veronica.jpg',
  'Kingdom Hearts IV': 'assets/games/kingdom_hearts_iv.jpg',
  'Fortnite': 'assets/games/fortnite.jpg',
  'Valorant': 'assets/games/valorant.jpg',
  'Minecraft': 'assets/games/minecraft.jpg',
  'League of Legends': 'assets/games/league_of_legends.jpg',
  'Genshin Impact': 'assets/games/genshin_impact.jpg',
  'Roblox': 'assets/games/roblox.jpg',
  'The Legend of Zelda: Tears of the Kingdom': 'assets/games/the_legend_of_zelda_tears_of_the_kingdom.jpg',
  'Pokémon Scarlet & Violet': 'assets/games/pokemon_scarlet_and_violet.jpg',
  "Marvel's Wolverine": 'assets/games/marvels_wolverine.jpg',
  'Gran Turismo 7': 'assets/games/gran_turismo_7.jpg',
  'Mario Kart 8 Deluxe': 'assets/games/mario_kart_8_deluxe.jpg',
  'Super Smash Bros. Ultimate': 'assets/games/super_smash_bros_ultimate.jpg',
  'Splatoon 3': 'assets/games/splatoon_3.jpg',
  'Grand Theft Auto VI': 'assets/games/grand_theft_auto_vi.jpg',
  'The Witcher 4': 'assets/games/the_witcher_4.jpg',
};
const kCountries = [
  'Argentina', 'Australia', 'Austria', 'Belgium', 'Brazil', 'Canada', 'Chile', 'China', 'Colombia', 'Czechia',
  'Denmark', 'Egypt', 'Finland', 'France', 'Germany', 'Greece', 'Hong Kong', 'India', 'Indonesia', 'Ireland',
  'Israel', 'Italy', 'Japan', 'Kenya', 'Malaysia', 'Mexico', 'Netherlands', 'New Zealand', 'Nigeria', 'Norway',
  'Pakistan', 'Philippines', 'Poland', 'Portugal', 'Saudi Arabia', 'Singapore', 'South Africa', 'South Korea',
  'Spain', 'Sweden', 'Switzerland', 'Thailand', 'Turkey', 'UAE', 'United Kingdom', 'United States', 'Vietnam',
  'Other',
];
const kGames = [
  'Apex Legends', 'Call of Duty: Warzone', 'Call of Duty: Modern Warfare III', 'Call of Duty: Black Ops 6',
  'EA Sports FC 25', 'EA Sports FC 26', 'FIFA 23', 'Fortnite', 'Grand Theft Auto V', 'Grand Theft Auto VI',
  'Halo Infinite', 'Halo: The Master Chief Collection', 'Minecraft', 'Valorant', 'Rocket League', 'Elden Ring',
  'Elden Ring Nightreign', 'Black Myth: Wukong', 'God of War Ragnarök', 'God of War (2018)',
  'The Legend of Zelda: Breath of the Wild', 'The Legend of Zelda: Tears of the Kingdom',
  'The Legend of Zelda: Echoes of Wisdom', 'Pokémon Scarlet & Violet', 'Pokémon Legends: Arceus', 'Pokémon Unite',
  'Tekken 8', 'Street Fighter 6', 'Mortal Kombat 1', 'F1 24', 'F1 25', 'Genshin Impact', 'Honkai: Star Rail',
  'Zenless Zone Zero', 'Wuthering Waves', 'Overwatch 2', 'Counter-Strike 2', 'League of Legends', 'Dota 2',
  'Destiny 2', 'Rainbow Six Siege', 'Warframe', 'Roblox', 'Among Us', 'Fall Guys', 'Helldivers 2',
  "Baldur's Gate 3", 'Cyberpunk 2077', 'The Witcher 3', 'Red Dead Redemption 2', 'Marvel Rivals',
  'Super Smash Bros. Ultimate', 'Mario Kart 8 Deluxe', 'Splatoon 3', 'Animal Crossing: New Horizons',
  'Super Mario Odyssey', 'Monster Hunter Wilds', 'Monster Hunter: World', 'Diablo IV', 'World of Warcraft',
  'Path of Exile 2', 'Rust', 'ARK: Survival Ascended', 'Valheim', 'Palworld', 'Lethal Company', 'Phasmophobia',
  'Sea of Thieves', 'PUBG: Battlegrounds', 'Escape from Tarkov', 'The Finals', 'Battlefield 2042',
  'Battlefield 6', 'NBA 2K25', 'Madden NFL 25', 'Gran Turismo 7', 'Forza Horizon 5', 'Forza Motorsport',
  'Assetto Corsa', 'iRacing', 'Stardew Valley', 'Terraria', 'Hollow Knight', 'Hades II', 'Dark Souls III',
  'Sekiro: Shadows Die Twice', 'Bloodborne', 'Brawl Stars', 'Clash Royale', 'Smite 2', 'Deadlock',
  'Dead by Daylight', 'Left 4 Dead 2', 'Split Fiction', 'It Takes Two', 'Overcooked! 2', 'Splitgate 2',
];
final kSorted = <String>{...kGames, ...kPopular}.toList()..sort();

// ───────────────────────── Models & State ─────────────────────────
class GameInfo {
  int rating; // 1 = rarely, 2 = sometimes, 3 = often / main game
  String note;
  GameInfo([this.rating = 2, this.note = '']);
}

class Profile {
  String first = '', last = '', email = '', phone = '', username = '', password = '';
  String gender = 'Prefer not to say', country = 'United Kingdom', bio = '', avail = 'Anytime';
  int avatar = 0;
  Uint8List? avatarBytes; // photo uploaded from the device (overrides the preset avatar)
  bool showGroups = true;
  final Set<String> followed = {}; // games the user follows
  bool emailVerified = false, showBuyLinks = true;
  final Set<String> hideStats = {}; // games whose stats the user hides
  final Map<String, bool> notif = {
    'Messages': true,
    'Friend requests': true,
    'Group activity': true,
    'News & releases': true,
    'Event reminders': true,
    'Commendations': true,
    'LFG & matches': true,
    'Achievements & ranks': true,
    'Safety & support': true,
  };
  // Ranks, roles and play style (shown on your public profile, subject to Privacy)
  final Map<String, String> gameRank = {}, gameRole = {}, gamePicks = {};
  String playStyle = 'Casual', lookingFor = 'Regular squad', languages = 'English', pronouns = '', askMe = '', discord = '', twitch = '';
  bool hasMic = true;
  int theme = 0;
  final Set<String> gamerTypes = {}, wants = {}, avoids = {}; // what you are, what you want, who to hide
  bool showFiltered = false;
  DateTime? dob;
  List<String> games = [];
  Map<String, GameInfo> gameInfo = {};
  Map<String, bool> linked = {
    'PlayStation / PSN': false,
    'Xbox / Microsoft': false,
    'Nintendo Account': false,
    'Steam / PC': false,
    'Discord': false,
  };
  Map<String, String> privacy = {
    'Gamertag': 'Public',
    'Games': 'Public',
    'Bio': 'Public',
    'Age / DOB': 'Friends Only',
    'Email': 'Private',
    'Game stats': 'Public',
    'Rank': 'Public',
    'Play style & comms': 'Public',
    'Activity & reliability': 'Public',
    'Social links': 'Friends Only',
  };
  final Map<String, bool> linkedVisibility = {
    'PlayStation / PSN': true,
    'Xbox / Microsoft': true,
    'Nintendo Account': true,
    'Steam / PC': true,
    'Discord': true,
  };
  bool anonymousGamertag = false;
  bool pushNotifications = true, emailNotifications = true;
  bool showOnlineStatus = true, allowFriendRequests = true;
  GameInfo info(String g) => gameInfo.putIfAbsent(g, () => GameInfo());
}

class Player {
  final String tag, platform, role, rank, region, avail, real, gender, bio;
  final int age, avatar;
  final List<String> games;
  final Map<String, String> priv;
  String status;
  Player(this.tag, this.platform, this.role, this.rank, this.region, this.avail, this.age, this.status, this.games,
      {this.real = '', this.priv = const {}, int? av})
      : avatar = av ?? tag.codeUnits.fold<int>(0, (a, b) => a + b) % 10,
        gender = kGenders[tag.length % 4],
        bio = kBios[tag.length % kBios.length];
  String vis(String k) => priv[k] ?? 'Public';
  int rating(int i) => (tag.length + i * 2) % 3 + 1;
  String note(int i) => kNotes[(tag.length + i) % kNotes.length];
}

class Msg {
  final String text;
  final bool mine;
  final DateTime t = DateTime.now();
  Msg(this.text, this.mine);
}

class Chat {
  final Player p;
  final List<Msg> msgs;
  int unread = 0;
  bool muted = false;
  Chat(this.p, this.msgs);
}

final kPlayers = <Player>[
  Player('NovaStrike', 'PlayStation', 'Fragger', 'Advanced', 'Europe', 'Weekday evenings', 22, 'online', ['Apex Legends', 'Call of Duty: Warzone'], real: 'Alex Novak'),
  Player('PixelPaladin', 'Xbox', 'Support', 'Intermediate', 'North America', 'Weekends', 27, 'away', ['Halo Infinite', 'Destiny 2'], real: 'Priya Shah'),
  Player('ShadowByte', 'PC', 'Entry Fragger', 'Elite', 'Europe', 'Late nights', 19, 'online', ['Valorant', 'Counter-Strike 2'], real: 'Jonas Weber', priv: {'Age / DOB': 'Friends Only'}),
  Player('LunaLynx', 'Nintendo Switch', 'Flex', 'Casual', 'Asia', 'Anytime', 24, 'offline', ['Splatoon 3', 'Super Smash Bros. Ultimate', 'Mario Kart 8 Deluxe'], real: 'Mei Tanaka', priv: {'Gamertag': 'Friends Only'}),
  Player('TurboTed', 'PlayStation', 'Striker', 'Intermediate', 'Europe', 'Weekday evenings', 31, 'online', ['EA Sports FC 27', 'Rocket League'], real: 'Ted Marlow'),
  Player('KageRonin', 'PC', 'Duelist', 'Advanced', 'Asia', 'Weekends', 20, 'away', ['Tekken 8', 'Street Fighter 6'], real: 'Kenji Mori'),
  Player('BlockBard', 'PC', 'Builder', 'Beginner', 'North America', 'Anytime', 15, 'online', ['Minecraft', 'Fortnite'], real: 'Sam Rivera', priv: {'Age / DOB': 'Private', 'Bio': 'Friends Only'}),
  Player('RiftRaven', 'PC', 'Jungler', 'Elite', 'North America', 'Late nights', 26, 'offline', ['League of Legends', 'Valorant'], real: 'Dana Cole', priv: {'Bio': 'Private', 'Groups': 'Private'}),
  Player('MaverickMia', 'Xbox', 'Driver', 'Advanced', 'Europe', 'Weekends', 29, 'online', ['Forza Horizon 5', 'F1 24'], real: 'Mia Fontaine'),
  Player('EmberKnight', 'PlayStation', 'Tank', 'Advanced', 'Oceania', 'Weekday evenings', 34, 'away', ['Elden Ring', 'Black Myth: Wukong', 'God of War Ragnarök'], real: 'Liam Hartley'),
  Player('ZeldaZed', 'Nintendo Switch', 'Explorer', 'Casual', 'Europe', 'Weekends', 17, 'online', ['The Legend of Zelda: Tears of the Kingdom', 'Pokémon Scarlet & Violet'], real: 'Zed Okafor'),
  Player('GlitchQueen', 'PC', 'Sniper', 'Intermediate', 'South America', 'Late nights', 23, 'online', ['Fortnite', 'Apex Legends'], real: 'Camila Duarte'),
  Player('CaptainClutch', 'Xbox', 'IGL', 'Elite', 'North America', 'Weekday evenings', 28, 'online', ['Call of Duty: Modern Warfare 4', 'Halo Infinite'], real: 'Marcus Bell'),
  Player('SakuraSpark', 'PC', 'Healer', 'Intermediate', 'Asia', 'Anytime', 21, 'away', ['Genshin Impact', 'Honkai: Star Rail'], real: 'Sakura Ito'),
  ..._genPlayers(),
];

List<Player> _genPlayers() {
  const tags = [
    'AceVortex', 'BlitzFox', 'CrimsonWave', 'DriftKing', 'EchoPilot', 'FrostByte', 'GhostLoop', 'HexRunner',
    'IronPulse', 'JadeViper', 'KiloStorm', 'LagLord', 'MintyMage', 'NeonNomad', 'OrbitOtter', 'PixelPanda',
    'QuasarQ', 'RogueRay', 'SolarSage', 'TinyTitan', 'UltraUma', 'VoltVixen', 'WispWolf', 'ZenZapper',
  ];
  const roles = ['Fragger', 'Support', 'Flex', 'Tank', 'Strategist', 'Scout'];
  const states = ['online', 'away', 'offline', 'online'];
  return [
    for (var i = 0; i < tags.length; i++)
      Player(tags[i], kPlatforms[i % 4], roles[i % 6], kRanks[(i * 3) % 5], kRegions[(i * 2) % 7], kAvail[(i + 1) % 4],
          16 + (i * 7) % 24, states[i % 4],
          _pickGames(i)),
  ];
}

List<String> _pickGames(int i) {
  final live = kPopular.where((g) => !kUpcoming.containsKey(g)).toList();
  final soon = kUpcoming.keys.toList();
  return <String>{
    live[(i * 5) % live.length],
    live[(i * 11 + 7) % live.length],
    i % 3 == 0 ? soon[(i ~/ 3) % soon.length] : live[(i * 3 + 14) % live.length],
  }.toList();
}

const _replies = [
  "Sounds good! What's your rank?",
  'I can play in about 30 minutes 🎮',
  'Nice — add me and we can party up.',
  "Let's run a few games tonight!",
  'GG! Same time tomorrow?',
];

// ───────────────────────── Groups: models & permissions ─────────────────────────
String whoName(Object w) => w is Profile ? w.username : (w as Player).tag;
Widget whoAvatar(Object w, {double radius = 16}) =>
    w is Profile ? Avatar(w.avatar, radius: radius, bytes: w.avatarBytes) : Avatar((w as Player).avatar, radius: radius);

class GMember {
  final Object who; // a Profile (a real user) or a Player (mock user)
  String role; // owner | admin | member
  bool canChat, canAnnounce, canManage;
  GMember(this.who, {this.role = 'member', this.canChat = true, this.canAnnounce = false, this.canManage = false});
  final Set<String> labels = {}; // ids of the labels (positions / roles) the owner gave this member
  bool mod = false; // community moderator
  String get name => whoName(who);
}

class Post {
  final Object who;
  final String text;
  final DateTime t = DateTime.now();
  Post(this.who, this.text);
}

class Group {
  final String id;
  String name, description, platform, region;
  bool isPublic;
  final List<String> games;
  final List<GMember> members;
  final List<Post> chat = [], news = [];
  final List<Object> requests = [];
  bool isCommunity = false; // groups and communities are separate sections
  int? maxMembers; // null = no limit; the owner can change it any time
  String rules = '';
  bool rulesRequired = true;
  final Set<Object> accepted = {}, banned = {};
  final List<GLabel> labels = [];
  final List<LabelReq> labelReqs = [];
  late final List<GChannel> channels = [GChannel('General', chat), GChannel('Looking for game', []), GChannel('Off-topic', [])];
  bool get isFull => maxMembers != null && members.length >= maxMembers!;
  /// What non-members can see (the owner decides).
  final Map<String, bool> show = {'Description': true, 'Games': true, 'Members': true, 'Announcements': true, 'Labels': true, 'Squad sheet': true};
  Group(this.id, this.name, this.description, this.isPublic, this.games, this.platform, this.region, this.members);
  GMember? memberOf(Object? who) {
    if (who == null) return null;
    for (final m in members) {
      if (identical(m.who, who)) return m;
    }
    return null;
  }

  GMember get owner => members.firstWhere((m) => m.role == 'owner');
  bool canView(String key) => show[key] ?? false;
}

bool gIsMember(Group g) => g.memberOf(S.me) != null;
bool gIsOwner(Group g) => g.memberOf(S.me)?.role == 'owner';
bool gCanChat(Group g) {
  final m = g.memberOf(S.me);
  return m != null && (m.role == 'owner' || m.canChat);
}

bool gCanAnnounce(Group g) {
  final m = g.memberOf(S.me);
  return m != null && (m.role == 'owner' || (m.role == 'admin' && m.canAnnounce));
}

bool gCanManage(Group g) {
  final m = g.memberOf(S.me);
  return m != null && (m.role == 'owner' || (m.role == 'admin' && m.canManage) || (g.isCommunity && m.mod));
}

List<Group> _seedGroups(Profile demo) {
  GMember own(int i) => GMember(kPlayers[i], role: 'owner', canAnnounce: true, canManage: true);
  GMember adm(int i) => GMember(kPlayers[i], role: 'admin', canAnnounce: true, canManage: true);
  GMember mem(int i) => GMember(kPlayers[i]);
  final gs = <Group>[
    Group('g1', 'Apex Ranked Grind', 'Daily ranked pushes to Diamond and beyond. Mics on, no toxicity.', true, ['Apex Legends'], 'Any', 'Europe', [own(0), adm(11), mem(14), mem(19)]),
    Group('g2', 'FC Pro Clubs UK', 'Looking for a full 11 for Pro Clubs and Rivals on FC 27. Weeknights.', true, ['EA Sports FC 27', 'EA Sports FC 26'], 'PlayStation', 'Europe', [own(4), adm(8), mem(12), mem(16)]),
    Group('g3', 'Valorant Night Owls', 'Late-night competitive Valorant and CS2 for players who like to scrim.', false, ['Valorant', 'Counter-Strike 2'], 'PC', 'Any', [own(2), adm(7), mem(11)]),
    Group('g4', 'Souls Veterans', 'Boss runs, co-op summons and build chat for the Souls-like crowd.', true, ['Elden Ring', 'Black Myth: Wukong', 'God of War Ragnarök'], 'PlayStation', 'Oceania', [own(9), mem(5), mem(13), mem(15)]),
    Group('g5', 'GTA VI Day One Crew', 'Releasing Nov 19, 2026. Find your heist crew before launch!', true, ['Grand Theft Auto VI', 'Grand Theft Auto V'], 'PlayStation', 'Any', [own(12), mem(3), mem(10), mem(18)]),
    Group('g6', 'Cozy Co-op Corner', 'Chill farming, building and creature-collecting nights. All skill levels welcome.', true, ['Stardew Valley', 'Palworld', 'Minecraft'], 'PC', 'North America', [own(6), mem(1), mem(21)]),
    Group('g7', 'Switch Smash Club', 'Smash, Mario Kart and Splatoon sessions with friendly rivals.', false, ['Super Smash Bros. Ultimate', 'Mario Kart 8 Deluxe', 'Splatoon 3'], 'Nintendo Switch', 'Asia', [own(3), mem(10)]),
    Group('g8', 'SquadUp Demo HQ', 'The demo group: you own it, so you can try roles, permissions and join requests.', false, ['Apex Legends', 'Valorant', 'Persona 4 Revival'], 'Any', 'Any',
        [GMember(demo, role: 'owner', canAnnounce: true, canManage: true), adm(5), mem(13)]),
  ];
  gs[2].show.addAll({'Members': false, 'Announcements': false});
  gs[6].show.addAll({'Members': false, 'Announcements': false});
  gs[7].requests.addAll([kPlayers[9], kPlayers[12]]);
  gs[2].requests.add(demo); // demo: your request to join a private group is waiting on its owner
  for (final g in gs) {
    g.chat.add(Post(g.owner.who, 'Welcome to ${g.name}! Say hi 👋'));
    g.news.add(Post(g.owner.who, 'Group rules: be kind, communicate, and have fun.'));
  }
  return [...gs, ..._seedCommunities(demo, gs)];
}

const _groupReplies = ['Count me in!', 'Anyone up for a session tonight?', 'GG everyone 🎮', 'Nice, see you online.', 'I can host if we need a lobby.'];

final messengerKey = GlobalKey<ScaffoldMessengerState>();
void toast(String m) => messengerKey.currentState
  ?..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(m)));

class AppState extends ChangeNotifier {
  final users = <Profile>[
    Profile()
      ..first = 'Demo'
      ..last = 'Player'
      ..email = 'demo@squadup.gg'
      ..username = 'demo'
      ..password = 'password123'
      ..dob = DateTime(1999, 5, 17)
      ..avatar = 3
      ..avail = 'Weekday evenings'
      ..bio = 'Weekend grinder looking for a chill, communicative squad.'
      ..games = ['Apex Legends', 'Valorant', 'Rocket League']
      ..gameInfo = {
        'Apex Legends': GameInfo(3, 'Grinding for rank up'),
        'Valorant': GameInfo(2, 'Competitive but friendly'),
        'Rocket League': GameInfo(1, 'Chill player, just for fun'),
      }
      ..emailVerified = true
      ..linked['Steam / PC'] = true
      ..followed.addAll(['Grand Theft Auto VI', 'Fable']),
  ];
  Profile? me;
  final invited = <String>{};
  final friends = <String>{'NovaStrike', 'TurboTed'};
  late final List<Chat> chats = [
    Chat(kPlayers[0], [Msg('Hey! Up for some ranked tonight?', false)])..unread = 2,
    Chat(kPlayers[4], [Msg('GG last night, want to run it back?', false)])..unread = 1,
  ];

  /// The chat screen that is currently open (messages arriving in it are not "unread").
  Chat? activeChat;

  final blocked = <String>{};
  final reports = <String>[];
  late final List<FeedbackReport> feedback = _seedReports();
  final commends = <String, int>{};
  final myCommended = <String>{};
  late final List<LfgPost> lfg = _seedLfg();
  late final List<SquadEvent> events = _seedEvents();

  /// Friend requests other players sent to you.
  late final List<Player> incomingFriendReqs = [kPlayers[2], kPlayers[6], kPlayers[10]];

  int get totalUnread => chats.fold<int>(0, (a, c) => a + c.unread);
  List<Group> get manageableGroups => me == null ? [] : groups.where((g) => gCanManage(g)).toList();
  int get pendingApprovals => manageableGroups.fold<int>(0, (a, g) => a + g.requests.length);
  List<Group> get myPendingJoins => me == null ? [] : groups.where((g) => g.requests.any((r) => identical(r, me))).toList();
  int get notificationCount => totalUnread + incomingFriendReqs.length + pendingApprovals;

  void touch() {
    notifyListeners();
    checkAchievements();
  }

  void acceptFriend(Player p) {
    incomingFriendReqs.remove(p);
    friends.add(p.tag);
    final c = chatWith(p);
    if (c == null) {
      chats.insert(0, Chat(p, [Msg("Thanks for adding me — let's squad up! 🎮", false)])..unread = 1);
    }
    notifyListeners();
    toast('You and ${p.tag} are now squad mates');
  }

  void declineFriend(Player p) {
    incomingFriendReqs.remove(p);
    notifyListeners();
  }

  void cancelInvite(Player p) {
    invited.remove(p.tag);
    notifyListeners();
    toast('Request to ${p.tag} cancelled');
  }

  void cancelJoin(Group g) {
    g.requests.removeWhere((r) => identical(r, me));
    notifyListeners();
    toast('Request to join ${g.name} cancelled');
  }

  void toggleFollow(String game) {
    final u = me;
    if (u == null) return;
    if (!u.followed.remove(game)) {
      u.followed.add(game);
      toast('Following $game');
    } else {
      toast('Unfollowed $game');
    }
    notifyListeners();
  }

  /// Demo: a squad mate pings you so the unread badge visibly updates.
  void simulatePing() {
    for (final c in chats) {
      if (!identical(c, activeChat) && !c.muted && friends.contains(c.p.tag)) {
        c.msgs.add(Msg('Yo, are you around tonight? 🎮', false));
        c.unread++;
        notifyListeners();
        pushNotice('Messages', Icons.chat_bubble, c.p.tag, 'Yo, are you around tonight? 🎮', chat: c);
        return;
      }
    }
  }

  late final List<Group> groups = _seedGroups(users[0]);
  List<Group> groupsOf(Object who) => groups.where((g) => g.memberOf(who) != null).toList();

  void joinGroup(Group g) {
    final u = me;
    if (u == null || g.memberOf(u) != null) return;
    if (g.banned.contains(u)) {
      toast('You cannot join ${g.name}');
      return;
    }
    if (g.isFull) {
      toast('${g.name} is full');
      return;
    }
    if (g.isPublic) {
      g.members.add(GMember(u));
      g.chat.add(Post(u, 'joined the group 👋'));
      toast('You joined ${g.name}');
    } else {
      if (!g.requests.any((r) => identical(r, u))) g.requests.add(u);
      toast('Request sent to the owner of ${g.name}');
    }
    notifyListeners();
  }

  void leaveGroup(Group g) {
    g.members.removeWhere((m) => identical(m.who, me));
    notifyListeners();
  }

  Group createGroup(String name, String desc, bool pub, List<String> games, String plat, String reg, Map<String, bool> show,
      {bool community = false, int? max, String template = 'Start blank', String rules = ''}) {
    final g = Group('g${DateTime.now().millisecondsSinceEpoch}', name, desc, pub, games, plat, reg,
        [GMember(me!, role: 'owner', canAnnounce: true, canManage: true)]);
    g.show.addAll(show);
    g.isCommunity = community;
    g.maxMembers = max;
    g.rules = rules;
    applyTemplate(g, template);
    g.chat.add(Post(me!, 'Welcome to $name! 🎮'));
    groups.insert(0, g);
    notifyListeners();
    return g;
  }

  void deleteGroup(Group g) {
    groups.remove(g);
    notifyListeners();
  }

  void approve(Group g, Object who, bool ok) {
    g.requests.remove(who);
    if (ok && g.isFull) {
      toast('${g.name} is full. Raise the member limit to approve more people.');
    } else if (ok) {
      g.members.add(GMember(who));
    }
    notifyListeners();
  }

  void announce(Group g, String text) {
    g.news.insert(0, Post(me!, text));
    notifyListeners();
  }

  void groupSay(Group g, String text, {List<Post>? into}) {
    final list = into ?? g.chat;
    list.add(Post(me!, text));
    notifyListeners();
    Timer(const Duration(milliseconds: 1400), () {
      final others = g.members.where((m) => !identical(m.who, me) && m.canChat).toList();
      if (others.isEmpty || !groups.contains(g)) return;
      list.add(Post(others[list.length % others.length].who, _groupReplies[list.length % _groupReplies.length]));
      notifyListeners();
    });
  }

  void update() {
    notifyListeners();
    checkAchievements();
  }
  Profile? find(String id) {
    final i = id.trim().toLowerCase();
    for (final u in users) {
      if (u.email.toLowerCase() == i || u.username.toLowerCase() == i) return u;
    }
    return null;
  }

  bool usernameTaken(String n, {Profile? except}) {
    for (final u in users) {
      if (u != except && u.username.toLowerCase() == n.trim().toLowerCase()) return true;
    }
    return false;
  }

  String? login(String id, String pw) {
    final u = find(id);
    if (u == null || u.password != pw) return 'Incorrect email/username or password';
    me = u;
    return null;
  }

  void register(Profile p) {
    users.add(p);
    me = p;
    notifyListeners();
  }

  Chat? chatWith(Player p) {
    for (final c in chats) {
      if (c.p == p) return c;
    }
    return null;
  }

  Chat startChat(Player p) {
    final c = chatWith(p);
    if (c != null) return c;
    final n = Chat(p, []);
    chats.insert(0, n);
    notifyListeners();
    return n;
  }

  void invite(Player p) {
    invited.add(p.tag);
    notifyListeners();
    toast('Squad request sent to ${p.tag}');
    Timer(const Duration(seconds: 10), () {
      if (!invited.contains(p.tag) || friends.contains(p.tag)) return; // cancelled or already friends
      friends.add(p.tag);
      final c = chatWith(p);
      if (c == null) {
        chats.insert(0, Chat(p, [Msg("Thanks for the invite — let's squad up! 🎮", false)])..unread = 1);
      } else {
        c.msgs.add(Msg("Thanks for the invite — let's squad up! 🎮", false));
        if (!identical(c, activeChat) && !c.muted) c.unread++;
      }
      notifyListeners();
      pushNotice('Friend requests', Icons.how_to_reg, 'Squad request accepted', '${p.tag} accepted your invite. Say hi!', chat: chatWith(p));
      checkAchievements();
    });
  }

  void send(Chat c, String text) {
    c.msgs.add(Msg(text, true));
    notifyListeners();
    Timer(const Duration(milliseconds: 1200), () {
      final reply = _replies[c.msgs.length % _replies.length];
      c.msgs.add(Msg(reply, false));
      if (!identical(c, activeChat) && !c.muted) {
        c.unread++;
        pushNotice('Messages', Icons.chat_bubble, c.p.tag, reply, chat: c);
      }
      notifyListeners();
    });
  }
}

final S = AppState();

// ───────────────────────── Helpers & matching ─────────────────────────
int ageOf(DateTime d) {
  final n = DateTime.now();
  var a = n.year - d.year;
  if (n.month < d.month || (n.month == d.month && n.day < d.day)) a--;
  return a;
}

String fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String fmtTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
Color statusColor(String s) => s == 'online' ? kOnline : (s == 'away' ? Colors.amber : Colors.grey);
ButtonStyle bigBtn() => FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: const StadiumBorder(), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
void goTo(BuildContext c, Widget w) => Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => w), (r) => false);
void openPlayer(BuildContext c, Player p) => Navigator.push(c, MaterialPageRoute(builder: (_) => PlayerProfileScreen(p)));
void openGame(BuildContext c, String g) => Navigator.push(c, MaterialPageRoute(builder: (_) => GamePlayersScreen(g)));
void openGroup(BuildContext c, Group g) => Navigator.push(c, MaterialPageRoute(builder: (_) => GroupScreen(g)));
void logout(BuildContext c) {
  squadTheme.value = ThemeMode.dark; // login / sign-up are always dark
  S.me = null;
  resetAchievementWatch();
  goTo(c, const WelcomeScreen());
}

Widget meAvatar({double radius = 24, String? status}) =>
    Avatar(S.me?.avatar ?? 0, radius: radius, status: status, bytes: S.me?.avatarBytes);

Widget lockedRow(String t) => Row(children: [
      const Icon(Icons.lock_outline, size: 16, color: kMuted),
      const SizedBox(width: 8),
      Expanded(child: Text(t, style: const TextStyle(color: kMuted))),
    ]);

Widget infoChip(String t, {IconData? icon, Widget? lead, Color? color}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, const SizedBox(width: 6)],
        if (icon != null) ...[Icon(icon, size: 13, color: color ?? kMuted), const SizedBox(width: 4)],
        Flexible(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
      ]),
    );

Widget gameThumb(String g, {double w = 22, double h = 22}) =>
    SizedBox(width: w, height: h, child: ClipRRect(borderRadius: BorderRadius.circular(5), child: CoverImage(g, compact: true)));

Future<void> pickPhoto(Profile p, VoidCallback done) async {
  try {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 88);
    if (x == null) return;
    p.avatarBytes = await x.readAsBytes();
    done();
  } catch (_) {
    toast('Could not open the photo picker on this device');
  }
}

void openChat(BuildContext c, Chat ch) => Navigator.push(c, MaterialPageRoute(builder: (_) => ChatScreen(ch)));

bool canSee(Player p, String key) {
  final v = p.vis(key);
  return v == 'Public' || (v == 'Friends Only' && S.friends.contains(p.tag));
}

String regionOf(String c) {
  const m = {
    'North America': ['Canada', 'Mexico', 'United States'],
    'South America': ['Argentina', 'Brazil', 'Chile', 'Colombia'],
    'Asia': ['China', 'Hong Kong', 'India', 'Indonesia', 'Japan', 'Malaysia', 'Pakistan', 'Philippines', 'Singapore', 'South Korea', 'Thailand', 'Vietnam'],
    'Oceania': ['Australia', 'New Zealand'],
    'Africa': ['Egypt', 'Kenya', 'Nigeria', 'South Africa'],
    'Middle East': ['Israel', 'Saudi Arabia', 'Turkey', 'UAE'],
  };
  for (final e in m.entries) {
    if (e.value.contains(c)) return e.key;
  }
  return 'Europe';
}

/// Match score 0-100: shared games 30, what you want in teammates 20, frequency 15, age 10, availability 10, region 10, rank closeness 5.
int matchScore(Profile me, Player p) {
  final shared = [
    for (var i = 0; i < p.games.length; i++)
      if (me.games.contains(p.games[i])) i
  ];
  final small = me.games.length < p.games.length ? me.games.length : p.games.length;
  final gScore = me.games.isEmpty ? 0.0 : shared.length / (small < 1 ? 1 : small);
  var f = 0.0;
  for (final i in shared) {
    f += 1 - (me.info(p.games[i]).rating - p.rating(i)).abs() / 2;
  }
  f = shared.isEmpty ? 0.0 : f / shared.length;
  final ageS = me.dob == null ? 0.5 : (1 - (ageOf(me.dob!) - p.age).abs() / 15).clamp(0.0, 1.0);
  final regS = regionOf(me.country) == p.region ? 1.0 : 0.0;
  final avS = me.avail == p.avail ? 1.0 : (me.avail == 'Anytime' || p.avail == 'Anytime' ? 0.7 : 0.0);
  var rSum = 0.0, rN = 0;
  for (final i in shared) {
    final g = p.games[i];
    final l = ladderOf(g);
    final mine = me.gameRank[g];
    final theirs = playerRank(p, g);
    if (l == null || mine == null || mine == kUnranked || theirs == null || theirs == kUnranked) continue;
    rSum += 1 - ((l.indexOf(mine) - l.indexOf(theirs)).abs() / (l.length - 1)).clamp(0.0, 1.0).toDouble();
    rN++;
  }
  final rS = rN == 0 ? 0.5 : rSum / rN;
  return (gScore * 30 + f * 15 + ageS * 10 + regS * 10 + avS * 10 + rS * 5 + tagScore(me, p) * 20).round().clamp(0, 100).toInt();
}

List<(Player, int)> ranked(Iterable<Player> ps) {
  final me = S.me;
  final l = <(Player, int)>[for (final p in ps) if (!S.blocked.contains(p.tag) && (me == null || !hiddenByPrefs(me, p))) (p, me == null ? 0 : matchScore(me, p))];
  l.sort((a, b) => b.$2.compareTo(a.$2));
  return l;
}

List<Player> playersOf(String g) => kPlayers.where((p) => p.games.contains(g)).toList();
int onlineCount(String g) => 60 + playersOf(g).length * 23 + (g.codeUnits.fold<int>(0, (a, b) => a + b) * 13) % 70;
List<String> popularGames() => [...kPopular]..sort((a, b) => onlineCount(b).compareTo(onlineCount(a)));
String? coverUrl(String g) {
  final o = kCoverOverrides[g];
  if (o != null) return o;
  final id = kSteam[g];
  return id == null ? null : 'https://cdn.cloudflare.steamstatic.com/steam/apps/$id/header.jpg';
}

BoxDecoration coverDeco(String g, {double r = 16}) {
  final h = (g.codeUnits.fold<int>(0, (a, b) => a + b) * 7 % 360).toDouble();
  return BoxDecoration(
    borderRadius: BorderRadius.circular(r),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [HSLColor.fromAHSL(1, h, 0.6, 0.32).toColor(), HSLColor.fromAHSL(1, (h + 40) % 360, 0.5, 0.14).toColor()],
    ),
  );
}

IconData gameIcon(String g) => kCoverIcons[g.length % kCoverIcons.length];

Widget pageTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Text(t, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    );

/// Field heading placed clearly ABOVE the box (never floating on the border).
Widget outLabel(String label, Widget field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
        field,
      ],
    );

Widget tf(TextEditingController c, String label,
        {IconData? icon, String? Function(String?)? v, bool obscure = false, TextInputType? type, int lines = 1, int? max}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: outLabel(
        label,
        TextFormField(
          controller: c,
          obscureText: obscure,
          keyboardType: type,
          maxLines: lines,
          maxLength: max,
          validator: v,
          decoration: InputDecoration(prefixIcon: icon == null ? null : Icon(icon)),
        ),
      ),
    );

String? reqV(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
String? emailV(String? v) =>
    (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null;

Widget searchField(TextEditingController c, ValueChanged<String> cb) => TextField(
      controller: c,
      onChanged: cb,
      decoration: InputDecoration(
        hintText: 'Search players or games…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: c.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  c.clear();
                  cb('');
                },
              ),
      ),
    );

Future<String?> pickSheet(BuildContext context, String title, List<String> options, String value) =>
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
          child: ListView(shrinkWrap: true, children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: o == value ? const Icon(Icons.check, color: kAccent) : null,
                onTap: () => Navigator.pop(c, o),
              ),
          ]),
        ),
      ),
    );

class PickField extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const PickField({super.key, required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => outLabel(
        label,
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final r = await pickSheet(context, label, options, value);
            if (r != null) onChanged(r);
          },
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.arrow_drop_down)),
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
}

class Sec extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const Sec(this.title, this.child, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        // A Material (not a coloured Container) so ListTiles inside keep their ink and pass the debug check.
        child: Material(
          color: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2))),
                  if (action != null) action!,
                ]),
                const SizedBox(height: 12),
                child,
              ]),
            ),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  final int i;
  final double radius;
  final String? status;
  final Uint8List? bytes;
  const Avatar(this.i, {super.key, this.radius = 24, this.status, this.bytes});
  @override
  Widget build(BuildContext context) {
    final a = kAvatars[i % kAvatars.length];
    return Stack(children: [
      bytes != null
          ? CircleAvatar(radius: radius, backgroundColor: kField, backgroundImage: MemoryImage(bytes!))
          : CircleAvatar(radius: radius, backgroundColor: a.$2, child: Icon(a.$1, size: radius * 1.0, color: Colors.white)),
      if (status != null)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: statusColor(status!), shape: BoxShape.circle, border: Border.all(color: kCard, width: 2)),
          ),
        ),
    ]);
  }
}

class AvatarPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const AvatarPicker({super.key, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 12, children: [
        for (var i = 0; i < kAvatars.length; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: i == selected ? kAccent : Colors.transparent, width: 3)),
              child: Avatar(i, radius: 24),
            ),
          ),
      ]);
}

class AvatarChooser extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const AvatarChooser({super.key, required this.p, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(p.avatar, radius: 38, bytes: p.avatarBytes),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: () => pickPhoto(p, onChanged), icon: const Icon(Icons.upload), label: const Text('Upload photo')),
              if (p.avatarBytes != null)
                OutlinedButton(
                  onPressed: () {
                    p.avatarBytes = null;
                    onChanged();
                  },
                  child: const Text('Remove photo'),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Or pick an avatar', style: TextStyle(color: kMuted)),
        const SizedBox(height: 8),
        AvatarPicker(
          selected: p.avatarBytes == null ? p.avatar : -1,
          onChanged: (v) {
            p.avatar = v;
            p.avatarBytes = null;
            onChanged();
          },
        ),
      ]);
}

void showAvatarSheet(BuildContext context, Profile p) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ListenableBuilder(
          listenable: S,
          builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AvatarChooser(p: p, onChanged: S.update),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))),
          ]),
        ),
      ),
    ),
  );
}

class RatingDots extends StatelessWidget {
  final int n;
  final double size;
  const RatingDots(this.n, {super.key, this.size = 12});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < n ? kAccent : Colors.transparent,
              border: Border.all(color: i < n ? kAccent : kMuted, width: 1.5),
            ),
          ),
      ]);
}

class MatchBar extends StatelessWidget {
  final int score;
  const MatchBar(this.score, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = score >= 75 ? kAccent : (score >= 50 ? Colors.amber : Colors.deepOrangeAccent);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('$score% Match', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 6,
          width: double.infinity,
          color: kField,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(widthFactor: score / 100, child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD54F), kAccent])))),
        ),
      ),
    ]);
  }
}

// ───────────────────────── Motion helpers ─────────────────────────
/// Subtle press-down scale for tappable cards and tabs. Purely visual: it only listens to
/// pointer events, so it never takes part in (or changes) tap/scroll gesture handling.
class Pressable extends StatefulWidget {
  final Widget child;
  final double scale;
  const Pressable({super.key, required this.child, this.scale = 0.97});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (e) {
          _origin = e.position;
          _set(true);
        },
        onPointerMove: (e) {
          // Release as soon as the finger starts scrolling instead of tapping.
          if (_down && _origin != null && (e.position - _origin!).distance > 12) _set(false);
        },
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Fades/slides its child in whenever [index] changes, without rebuilding the child,
/// so the IndexedStack of tabs keeps every tab's state and scroll position.
class TabFadeThrough extends StatefulWidget {
  final int index;
  final Widget child;
  const TabFadeThrough({super.key, required this.index, required this.child});
  @override
  State<TabFadeThrough> createState() => _TabFadeThroughState();
}

class _TabFadeThroughState extends State<TabFadeThrough> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(_fade);

  @override
  void didUpdateWidget(TabFadeThrough old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}

/// Small pop when a nav icon becomes selected.
class NavPop extends StatelessWidget {
  final Widget child;
  const NavPop(this.child, {super.key});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Transform.scale(scale: v, child: c),
        child: child,
      );
}

// ───────────────────────── Brand widgets ─────────────────────────
/// Picks the logo artwork for the current theme: white-ink version on dark, black-ink version on light.
String _logoAsset(BuildContext context, String kind) =>
    'assets/logos/squadup_logo_$kind${Theme.of(context).brightness == Brightness.dark ? '_dark' : ''}.png';

class LogoIcon extends StatelessWidget {
  final double size;
  const LogoIcon({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => Image.asset(
        _logoAsset(context, 'icon'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        semanticLabel: 'SquadUp',
      );
}

class LogoFull extends StatelessWidget {
  final double width;
  const LogoFull({super.key, this.width = 240});
  @override
  Widget build(BuildContext context) => Image.asset(
        _logoAsset(context, 'full'),
        width: width,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        semanticLabel: 'SquadUp',
      );
}

class GradientBar extends StatelessWidget {
  const GradientBar({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: 3, child: Column(children: [const Expanded(child: SizedBox()), SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: kBorder))]));
}

void openMyProfile(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const MyProfileScreen()));

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My profile & games'), bottom: const PreferredSize(preferredSize: Size.fromHeight(3), child: GradientBar())),
        body: const ProfileTab(),
      );
}

// ───────────────────────── App ─────────────────────────
final ValueNotifier<ThemeMode> squadTheme = ValueNotifier<ThemeMode>(ThemeMode.dark);

class SquadUpApp extends StatelessWidget {
  const SquadUpApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: squadTheme,
        builder: (context, mode, _) => MaterialApp(
          title: 'SquadUp',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          navigatorKey: navKey,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
          ),
          themeMode: mode,
          darkTheme: _buildTheme(Brightness.dark),
          theme: _buildTheme(Brightness.light),
          home: const WelcomeScreen(),
          builder: (context, child) => ValueListenableBuilder<double>(
            valueListenable: textScale,
            builder: (_, v, __) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(v)), child: Stack(fit: StackFit.expand, children: [child!, const NoticeLayer()])),
          ),
        ),
      );
}

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF0D0D0D) : const Color(0xFFF3F5F8);
  final card = dark ? const Color(0xFF1A1A1A) : Colors.white;
  final raised = dark ? const Color(0xFF202020) : Colors.white;
  final field = dark ? const Color(0xFF242424) : const Color(0xFFECEFF3);
  final border = dark ? const Color(0x1FFFFFFF) : const Color(0x1A000000);
  final onBg = dark ? Colors.white : const Color(0xFF111111);
  final secondary = dark ? const Color(0xFFA0A0A5) : const Color(0xFF5F6670);
  final link = dark ? kAccentLight : kAccent;
  final blueContainer = dark ? const Color(0xFF0B2A4A) : const Color(0xFFD7E8FA);
  final onBlueContainer = dark ? Colors.white : const Color(0xFF002E57);

  final scheme = ColorScheme.fromSeed(seedColor: kAccent, brightness: brightness).copyWith(
    primary: kAccent,
    onPrimary: Colors.white,
    primaryContainer: blueContainer,
    onPrimaryContainer: onBlueContainer,
    secondary: link,
    onSecondary: Colors.white,
    secondaryContainer: blueContainer,
    onSecondaryContainer: onBlueContainer,
    tertiary: link,
    surface: card,
    onSurface: onBg,
    onSurfaceVariant: secondary,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: bg,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: raised,
    surfaceContainerHighest: field,
    outline: dark ? const Color(0x33FFFFFF) : const Color(0x33000000),
    outlineVariant: border,
  );

  final base = ThemeData(brightness: brightness, useMaterial3: true, colorScheme: scheme);
  final t = base.textTheme.apply(bodyColor: onBg, displayColor: onBg);
  final textTheme = t.copyWith(
    displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800),
    headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodySmall: t.bodySmall?.copyWith(color: secondary),
    labelSmall: t.labelSmall?.copyWith(color: secondary),
  );
  final r12 = BorderRadius.circular(12);

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: card,
    dividerColor: border,
    textTheme: textTheme,
    iconTheme: IconThemeData(color: onBg, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: onBg, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: onBg),
      actionsIconTheme: IconThemeData(color: onBg),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF121212) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 66,
      indicatorColor: kAccent.withAlpha(dark ? 70 : 40),
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(
            size: 24,
            color: st.contains(WidgetState.selected) ? (dark ? Colors.white : kAccent) : secondary,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
            fontSize: 11.5,
            fontWeight: st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: st.contains(WidgetState.selected) ? onBg : secondary,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      indicatorColor: kAccent.withAlpha(dark ? 70 : 40),
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(color: dark ? Colors.white : kAccent),
      unselectedIconTheme: IconThemeData(color: secondary),
      selectedLabelTextStyle: TextStyle(color: onBg, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: secondary, fontWeight: FontWeight.w500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: secondary),
      labelStyle: TextStyle(color: secondary),
      floatingLabelStyle: TextStyle(color: link),
      prefixIconColor: secondary,
      suffixIconColor: secondary,
      border: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: r12, borderSide: const BorderSide(color: kAccent, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: scheme.error, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: field,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onBg,
        side: BorderSide(color: dark ? const Color(0x59FFFFFF) : const Color(0x40000000), width: 1.2),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: link, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: onBg)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccent,
      foregroundColor: Colors.white,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: field,
      selectedColor: kAccent,
      secondarySelectedColor: kAccent,
      checkmarkColor: Colors.white,
      side: BorderSide(color: border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: onBg, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: secondary,
      textColor: onBg,
      selectedColor: link,
      shape: RoundedRectangleBorder(borderRadius: r12),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 24),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : secondary),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kAccent : field),
      trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kAccent : border),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kAccent : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kAccent : secondary)),
    sliderTheme: SliderThemeData(activeTrackColor: kAccent, thumbColor: Colors.white, inactiveTrackColor: field, overlayColor: kAccent.withAlpha(40)),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: kAccent, linearTrackColor: field, circularTrackColor: field),
    tabBarTheme: TabBarThemeData(
      labelColor: onBg,
      unselectedLabelColor: secondary,
      indicatorColor: kAccent,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: border,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: border)),
      titleTextStyle: TextStyle(color: onBg, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: raised,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: border)),
    ),
    menuTheme: MenuThemeData(style: MenuStyle(backgroundColor: WidgetStatePropertyAll(raised))),
    drawerTheme: DrawerThemeData(backgroundColor: card, surfaceTintColor: Colors.transparent),
    badgeTheme: const BadgeThemeData(backgroundColor: kAccent, textColor: Colors.white),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: dark ? const Color(0xFF2A2A2A) : const Color(0xFF333333), borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2A2A2A) : const Color(0xFF1F1F1F),
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: kAccentLight,
      shape: RoundedRectangleBorder(borderRadius: r12),
    ),
    datePickerTheme: DatePickerThemeData(backgroundColor: raised, surfaceTintColor: Colors.transparent, headerBackgroundColor: kAccent, headerForegroundColor: Colors.white),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? kAccent : field),
        foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : onBg),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
      ),
    ),
    visualDensity: VisualDensity.standard,
    // Press feedback: soft blue ripples/highlights everywhere (InkWell, ListTile, buttons, nav).
    splashFactory: InkRipple.splashFactory,
    splashColor: kAccent.withAlpha(48),
    highlightColor: kAccent.withAlpha(22),
    hoverColor: kAccent.withAlpha(16),
    focusColor: kAccent.withAlpha(30),
  );
}

// ───────────────────────── Auth ─────────────────────────
class AuthPage extends StatelessWidget {
  final String title;
  final Widget child;
  const AuthPage({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: const [Padding(padding: EdgeInsets.only(right: 14), child: LogoIcon(size: 32))]),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child),
          ),
        ),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0x660070CC), kBg]),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const LogoFull(width: 260),
                    const SizedBox(height: 16),
                    Text('Find your squad. Level up together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(190))),
                    const SizedBox(height: 36),
                    FilledButton(
                      style: bigBtn(),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text('Sign up'),
                    ),
                    const SizedBox(height: 28),
                    const Text('PlayStation • Xbox • Nintendo Switch • PC', style: TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      const Text('By continuing you agree to our ', style: TextStyle(color: kMuted, fontSize: 12)),
                      InkWell(onTap: () => openTerms(context), child: const Text('Terms', style: TextStyle(color: kAccent, fontSize: 12))),
                      const Text(' and ', style: TextStyle(color: kMuted, fontSize: 12)),
                      InkWell(onTap: () => openPrivacy(context), child: const Text('Privacy Policy', style: TextStyle(color: kAccent, fontSize: 12))),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final key = GlobalKey<FormState>();
  final id = TextEditingController(), pw = TextEditingController();

  void submit() {
    if (!key.currentState!.validate()) return;
    final err = S.login(id.text, pw.text);
    if (err != null) {
      toast(err);
      return;
    }
    goTo(context, const HomeShell());
  }

  void forgot() {
    final e = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Reset password'),
        content: outLabel('Email address', TextField(controller: e, keyboardType: TextInputType.emailAddress)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(d);
              toast('If an account exists, a reset link has been sent.');
            },
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthPage(
        title: 'Log in',
        child: Form(
          key: key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            tf(id, 'Email or username', icon: Icons.person_outline, v: reqV),
            tf(pw, 'Password', icon: Icons.lock_outline, obscure: true, v: reqV),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: forgot, child: const Text('Forgot password?'))),
            const SizedBox(height: 8),
            FilledButton(style: bigBtn(), onPressed: submit, child: const Text('Log in')),
            const SizedBox(height: 16),
            const Text('Demo account: demo / password123', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          ]),
        ),
      );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  int step = 0;
  final p = Profile();
  final k1 = GlobalKey<FormState>(), k3 = GlobalKey<FormState>();
  final fn = TextEditingController(), ln = TextEditingController(), em = TextEditingController();
  final ph = TextEditingController(), un = TextEditingController(), pw = TextEditingController();
  final un3 = TextEditingController(), bio = TextEditingController();
  String? dobErr;
  bool agreed = false;
  static const titles = ['Your details', 'About you', 'Your gaming profile'];

  String? userV(String? v) {
    if (v == null || v.trim().length < 3) return 'At least 3 characters';
    if (v.contains(' ')) return 'No spaces allowed';
    if (S.usernameTaken(v)) return 'Username already taken';
    return null;
  }

  void next() {
    if (step == 0) {
      if (!k1.currentState!.validate()) return;
      p
        ..first = fn.text.trim()
        ..last = ln.text.trim()
        ..email = em.text.trim()
        ..phone = ph.text.trim()
        ..password = pw.text;
      un3.text = un.text.trim();
    } else if (step == 1) {
      if (p.dob == null) {
        setState(() => dobErr = 'Please select your date of birth');
        return;
      }
      if (ageOf(p.dob!) < 13) {
        setState(() => dobErr = 'You must be 13 or older to use SquadUp');
        return;
      }
    } else {
      finish();
      return;
    }
    setState(() => step++);
  }

  void finish() {
    if (!k3.currentState!.validate()) return;
    if (p.games.isEmpty) {
      toast('Select at least one game');
      return;
    }
    if (!agreed) {
      toast('Please accept the Terms & Conditions and Privacy Policy');
      return;
    }
    p
      ..username = un3.text.trim()
      ..bio = bio.text.trim();
    if (p.dob != null && ageOf(p.dob!) < 18) p.privacy['Age / DOB'] = 'Private';
    S.register(p);
    goTo(context, const VerifyEmailScreen());
  }

  Widget s1() => Form(
        key: k1,
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: tf(fn, 'First name', v: reqV)),
            const SizedBox(width: 12),
            Expanded(child: tf(ln, 'Last name', v: reqV)),
          ]),
          tf(em, 'Email', icon: Icons.email_outlined, v: (v) {
            final e = emailV(v);
            if (e != null) return e;
            return S.find(v!) != null ? 'Email already registered' : null;
          }, type: TextInputType.emailAddress),
          tf(ph, 'Phone (optional)', icon: Icons.phone_outlined, type: TextInputType.phone),
          tf(un, 'Username', icon: Icons.alternate_email, v: userV),
          tf(pw, 'Password', icon: Icons.lock_outline, obscure: true, v: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null),
        ]),
      );

  Widget s2() => Column(children: [
        outLabel('Date of birth', InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: p.dob ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              setState(() {
                p.dob = d;
                dobErr = null;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(errorText: dobErr, prefixIcon: const Icon(Icons.cake_outlined)),
            child: Text(p.dob == null ? 'Select date' : fmtDate(p.dob!)),
          ),
        )),
        const SizedBox(height: 14),
        PickField(label: 'Gender', value: p.gender, options: kGenders, onChanged: (v) => setState(() => p.gender = v)),
        const SizedBox(height: 14),
        PickField(label: 'Country / Region', value: p.country, options: kCountries, onChanged: (v) => setState(() => p.country = v)),
        if (p.dob != null && ageOf(p.dob!) < 18)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shield_outlined, size: 18, color: kAccent),
                SizedBox(width: 8),
                Expanded(child: Text('You are under 18. Make sure a parent or guardian is happy for you to use SquadUp. We will hide your age by default.', style: TextStyle(fontSize: 12.5))),
              ]),
            ),
          ),
      ]);

  Widget s3() => Form(
        key: k3,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profile picture', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          AvatarChooser(p: p, onChanged: () => setState(() {})),
          const SizedBox(height: 20),
          tf(un3, 'Username', icon: Icons.alternate_email, v: userV),
          const Text('Your games', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GamesEditor(p: p, onChanged: () => setState(() {})),
          const SizedBox(height: 20),
          const Text('Link your accounts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          LinkedEditor(p: p, onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          tf(bio, 'Profile bio', lines: 4, max: 200),
          PickField(label: 'Availability', value: p.avail, options: kAvail, onChanged: (v) => setState(() => p.avail = v)),
          const SizedBox(height: 20),
          const Text('Privacy preferences', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          PrivacyEditor(p: p, onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: agreed,
            onChanged: (v) => setState(() => agreed = v ?? false),
            title: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('I am 13 or older and agree to the '),
              InkWell(onTap: () => openTerms(context), child: const Text('Terms & Conditions', style: TextStyle(color: kAccent))),
              const Text(' and '),
              InkWell(onTap: () => openPrivacy(context), child: const Text('Privacy Policy', style: TextStyle(color: kAccent))),
              const Text('.'),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => AuthPage(
        title: 'Create account',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Step ${step + 1} of 3: ${titles[step]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: (step + 1) / 3, minHeight: 8, backgroundColor: kCard, color: kAccent),
          ),
          const SizedBox(height: 24),
          [s1(), s2(), s3()][step],
          const SizedBox(height: 24),
          Row(children: [
            if (step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => setState(() => step--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: FilledButton(style: bigBtn(), onPressed: next, child: Text(step == 2 ? 'Finish' : 'Next'))),
          ]),
        ]),
      );
}

// ───────────────────────── Shared editors ─────────────────────────
class GamesEditor extends StatefulWidget {
  final Profile p;
  final VoidCallback onChanged;
  const GamesEditor({super.key, required this.p, required this.onChanged});
  @override
  State<GamesEditor> createState() => _GamesEditorState();
}

class _GamesEditorState extends State<GamesEditor> {
  final c = TextEditingController();

  Future<void> add(String g) async {
    var name = g;
    if (g == kCustom) {
      final t = TextEditingController();
      final r = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: kCard,
          title: const Text('Add custom game'),
          content: outLabel('Game name', TextField(controller: t, autofocus: true)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(d, t.text.trim()), child: const Text('Add')),
          ],
        ),
      );
      if (r == null || r.isEmpty) return;
      name = r;
    }
    if (!widget.p.games.contains(name)) widget.p.games.add(name);
    widget.onChanged();
  }

  Future<void> editGame(String g) async {
    final info = widget.p.info(g);
    var rating = info.rating;
    final nc = TextEditingController(text: info.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          backgroundColor: kCard,
          title: Text(g),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Play frequency rating', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                for (final n in [1, 2, 3])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: n < 3 ? 8 : 0),
                      child: rating == n
                          ? FilledButton(onPressed: () => set(() => rating = n), child: Text('$n'))
                          : OutlinedButton(onPressed: () => set(() => rating = n), child: Text('$n')),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(kRatingLabels[rating - 1], style: const TextStyle(color: kAccent, fontSize: 13)),
              const SizedBox(height: 16),
              outLabel(
                'Personal note',
                TextField(
                  controller: nc,
                  maxLength: 80,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'e.g. Looking for Pro Clubs squad'),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      info.rating = rating;
      info.note = nc.text.trim();
      widget.onChanged();
    }
  }

  Widget tile(int i) {
    final g = widget.p.games[i];
    final info = widget.p.info(g);
    return Padding(
      key: ValueKey(g),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Pressable(child: Material(
        color: kField,
        borderRadius: BorderRadius.circular(12),
        child: Row(children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => editGame(g),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: i == 0 ? kAccent : kCard,
                    foregroundColor: i == 0 ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (i == 0) const Padding(padding: EdgeInsets.only(left: 8), child: Text('Main', style: TextStyle(color: kAccent, fontSize: 11))),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        info.note.isEmpty ? 'Tap to rate and add a note' : info.note,
                        style: TextStyle(color: kMuted, fontSize: 13, fontStyle: info.note.isEmpty ? FontStyle.italic : FontStyle.normal),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Tooltip(message: kRatingLabels[info.rating - 1], child: RatingDots(info.rating)),
                  ),
                  const SizedBox(width: 6),
                  const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.edit_outlined, size: 16, color: kMuted)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
          ),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.p.games;
    final q = c.text.toLowerCase();
    final m = [kCustom, ...kSorted.where((x) => x.toLowerCase().contains(q))];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: c,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Search games…', prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 8),
      Material(
        color: kField,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: m.length,
            itemBuilder: (_, i) {
              final x = m[i];
              return ListTile(
                dense: true,
                leading: Icon(x == kCustom ? Icons.add_circle_outline : Icons.sports_esports, color: x == kCustom ? kAccent : null),
                title: Text(x),
                trailing: g.contains(x) ? const Icon(Icons.check, color: kAccent) : null,
                onTap: () => add(x),
              );
            },
          ),
        ),
      ),
      if (g.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final x in g)
            InputChip(
              label: Text(x),
              onDeleted: () {
                g.remove(x);
                widget.onChanged();
              },
            ),
        ]),
        const SizedBox(height: 12),
        const Text('Tap a game to rate it and add a note. Drag the handle to reorder (top = most played).', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 4),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (o, n) {
            if (n > o) n--;
            g.insert(n, g.removeAt(o));
            widget.onChanged();
          },
          children: [for (var i = 0; i < g.length; i++) tile(i)],
        ),
      ],
    ]);
  }
}

class LinkedEditor extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const LinkedEditor({super.key, required this.p, required this.onChanged});
  static const icons = [Icons.sports_esports, Icons.gamepad, Icons.videogame_asset, Icons.computer, Icons.forum];
  @override
  Widget build(BuildContext context) {
    final keys = p.linked.keys.toList();
    return Column(children: [
      for (var i = 0; i < keys.length; i++)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icons[i]),
          title: Text(keys[i]),
          subtitle: Text(p.linked[keys[i]]! ? 'Connected (demo) · ${p.linkedVisibility[keys[i]]! ? 'visible' : 'hidden'}' : 'Not connected'),
          value: p.linked[keys[i]]!,
          onChanged: (v) {
            p.linked[keys[i]] = v;
            onChanged();
            toast(v ? '${keys[i]} connected in demo mode' : '${keys[i]} disconnected');
          },
        ),
    ]);
  }
}

class PrivacyEditor extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const PrivacyEditor({super.key, required this.p, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final k in p.privacy.keys.toList())
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PickField(
              label: '$k visibility',
              value: p.privacy[k]!,
              options: kVis,
              onChanged: (v) {
                p.privacy[k] = v;
                onChanged();
              },
            ),
          ),
      ]);
}

// ───────────────────────── Welcome flow ─────────────────────────
class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({super.key});
  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  final pc = PageController();
  int i = 0;
  static const pages = [
    (Icons.celebration, 'Welcome!', 'Your profile is ready. Your games, accounts and privacy settings are all saved.'),
    (Icons.search, 'Find your squad', 'We rank players by how well they match your games, play style, age, region and availability.'),
    (Icons.chat_bubble_outline, 'Chat and play', 'Send squad invites, chat with teammates and jump into a match.'),
    (Icons.tune, 'Your play style', 'Pick what fits you.'),
  ];

  Widget _prefsPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your play style', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tell us what you are into so we can match you. You can skip this and change it any time on your profile.', style: TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          PrefsEditor(p: S.me!, onChanged: () => setState(() {})),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(children: [
                Align(alignment: Alignment.topRight, child: TextButton(onPressed: () => goTo(context, const HomeShell()), child: const Text('Skip'))),
                Expanded(
                  child: PageView(
                    controller: pc,
                    onPageChanged: (v) => setState(() => i = v),
                    children: [
                      for (var n = 0; n < pages.length; n++)
                        n == 3 && S.me != null
                            ? _prefsPage()
                            : Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            n == 0 && S.me != null ? meAvatar(radius: 48) : Icon(pages[n].$1, size: 96, color: kAccent),
                            const SizedBox(height: 24),
                            Text(n == 0 ? 'Welcome, ${S.me?.first ?? ''}!' : pages[n].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(pages[n].$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: kMuted)),
                          ]),
                        ),
                    ],
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var n = 0; n < pages.length; n++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: n == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: n == i ? kAccent : kMuted, borderRadius: BorderRadius.circular(4)),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton(
                    style: bigBtn(),
                    onPressed: () {
                      if (i < pages.length - 1) {
                        pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        goTo(context, const HomeShell());
                      }
                    },
                    child: Text(i < pages.length - 1 ? 'Next' : 'Get started'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── News data (SAMPLE / DEMO content) ─────────────────────────
class NewsItem {
  final String id, cat, title, summary, body, ago;
  final List<String> games;
  final IconData icon;
  const NewsItem(this.id, this.cat, this.title, this.summary, this.body, this.games, this.ago, this.icon);
}

const kNewsCats = ['Shooter', 'Battle Royale', 'Sports', 'Racing', 'Fighting', 'RPG / Adventure', 'Co-op / Party', 'Esports', 'Releases'];

/// Sample articles written for the demo. They are NOT live headlines — swap in a real news API later.
const kNews = <NewsItem>[
  NewsItem('n1', 'Releases', 'Grand Theft Auto VI: launch week is almost here',
      'Players are lining up squads ahead of the announced Nov 19, 2026 release.',
      'The announced release date for Grand Theft Auto VI is Nov 19, 2026. Release dates can still change, so check the official channels before planning your launch-night session.\n\nIf you want a crew on day one, follow the game on SquadUp and send squad requests to players who are already waiting for it.',
      ['Grand Theft Auto VI'], '1h ago', Icons.rocket_launch),
  NewsItem('n2', 'Releases', 'Persona 4 Revival and Fable: early-2027 line-up',
      'Two big RPG releases are announced for February 2027.',
      'Persona 4 Revival is listed for Feb 18, 2027 and Fable for Feb 23, 2027 in the SquadUp release tracker. Both dates are the latest announced and may move.\n\nFollow either game to see it on your Home dashboard countdown.',
      ['Persona 4 Revival', 'Fable'], '3h ago', Icons.event),
  NewsItem('n3', 'Sports', 'EA Sports FC 27: Pro Clubs squads are filling up',
      'Weeknight Pro Clubs lobbies are the most common request on SquadUp right now.',
      'Pro Clubs rewards teams that communicate: agree positions early, pick a captain, and keep a standing weeknight slot. Clubs with a full 11 find games faster than half-empty ones.\n\nSearch the Groups tab for "Pro Clubs" to find a club that matches your platform and region.',
      ['EA Sports FC 27'], '5h ago', Icons.sports_soccer),
  NewsItem('n4', 'Sports', 'Madden NFL 27: finding a regular franchise crew',
      'Online franchise leagues work best with a fixed schedule and a commissioner.',
      'If you want a long-running league, look for a group that already has a commissioner and written rules. Agree on game length, trade rules and a weekly deadline before the first kick-off.',
      ['Madden NFL 27'], '9h ago', Icons.sports_football),
  NewsItem('n5', 'Shooter', 'Call of Duty: Modern Warfare 4 players look for ranked partners',
      'Squads of four dominate the early ranked ladder.',
      'In team playlists a fixed four-stack usually beats random queues because roles and callouts are agreed in advance. Decide who anchors, who entries and who supports before you queue.',
      ['Call of Duty: Modern Warfare 4'], '12h ago', Icons.my_location),
  NewsItem('n6', 'Shooter', 'Gears of War: E-Day co-op: what to look for in a partner',
      'Campaign co-op rewards patient, communicative players.',
      'For story co-op, agree on a schedule and whether you want to play on a harder difficulty. A partner in a similar time zone makes finishing the campaign far more likely.',
      ['Gears of War: E-Day'], '14h ago', Icons.shield),
  NewsItem('n7', 'Shooter', 'Valorant: building a five-stack that actually communicates',
      'Role clarity beats raw aim in most ranked games.',
      'A balanced five usually has one or two entry players, a flex, a support and a controller. Keep comms short: call position, number of enemies, and what you need from the team.',
      ['Valorant'], '1d ago', Icons.gps_fixed),
  NewsItem('n8', 'Shooter', 'Counter-Strike 2: why a fixed lineup improves your rank',
      'Practising the same utility lineups with the same people pays off quickly.',
      'Set one map to practise per week, review one round together after each session, and agree who calls the mid-round. Small routines compound faster than long grinding sessions.',
      ['Counter-Strike 2'], '1d ago', Icons.flag),
  NewsItem('n9', 'Battle Royale', 'Apex Legends ranked: trios beat random squads',
      'Players with a regular trio climb more consistently.',
      'In ranked, consistent roles and a shared plan for where to land matter more than individual kills. Pick a drop spot you all like and a rotation rule before the match starts.',
      ['Apex Legends'], '1d ago', Icons.local_fire_department),
  NewsItem('n10', 'Battle Royale', 'Call of Duty: Warzone — team-up guide for duos and trios',
      'How to share loadouts, plates and revives without wasting time.',
      'Agree who carries the long-range option, who carries the close-range option, and who calls the contract choices. Keep a spare self-revive between you and always ping before you push.',
      ['Call of Duty: Warzone'], '2d ago', Icons.flight_land),
  NewsItem('n11', 'Battle Royale', 'PUBG: Battlegrounds — squad etiquette that wins matches',
      'Quiet mics at the right moments and clear callouts make a big difference.',
      'Call the circle early, share the vehicle, and decide beforehand whether you play aggressive or passive. A squad that agrees on a style almost always outlasts one that does not.',
      ['PUBG: Battlegrounds'], '2d ago', Icons.map),
  NewsItem('n12', 'Racing', 'F1 25: finding a league with a fair rule-set',
      'Good leagues publish their rules for penalties, tyres and race length.',
      'Before joining, check the race length, the penalty rules and the expected clean-racing standard. A league with a clear steward process saves arguments later.',
      ['F1 25'], '2d ago', Icons.flag_circle),
  NewsItem('n13', 'Racing', 'Forza Horizon 5: car meets and co-op convoys',
      'Casual convoy nights are a relaxed way to meet new players.',
      'Pick a theme (all-JDM, all-hypercar), agree a start point on the map and drive a loose route together. No pressure, just good company.',
      ['Forza Horizon 5'], '3d ago', Icons.directions_car),
  NewsItem('n14', 'Racing', 'Gran Turismo 7: sportsmanship ranking explained',
      'A clean-driving score keeps lobbies fair.',
      'Lobbies filtered by a clean-racing score keep contact low. If you race in a group, agree to start lobbies with the same restrictions so everyone has a fair grid.',
      ['Gran Turismo 7'], '3d ago', Icons.speed),
  NewsItem('n15', 'Fighting', 'Tekken 8 and Street Fighter 6: finding sparring partners',
      'Regular sparring partners improve faster than ranked grinding alone.',
      'Look for a partner within a rank or two of your own, play first-to-ten sets, and review replays together. Short, regular sessions beat one marathon a week.',
      ['Tekken 8', 'Street Fighter 6'], '3d ago', Icons.sports_mma),
  NewsItem('n16', 'Fighting', 'Fighting games: how to give (and take) feedback',
      'Good sparring partners are honest but kind.',
      'Name one thing you noticed per set — a habit, a missed punish, a movement tendency — and ask for the same in return. Feedback sticks when it is specific and short.',
      ['Street Fighter 6'], '4d ago', Icons.forum),
  NewsItem('n17', 'RPG / Adventure', "Marvel's Wolverine and Phantom Blade Zero: action-RPG talk",
      'Two action-heavy releases are drawing newcomers to the genre.',
      'If you are new to action games, start on a lower difficulty to learn the timing, then raise it as you improve. Sharing tips with a friend who is a few hours ahead makes the early game much smoother.',
      ["Marvel's Wolverine", 'Phantom Blade Zero'], '4d ago', Icons.auto_awesome),
  NewsItem('n18', 'RPG / Adventure', 'Control: Resonant — story-first players compare notes',
      'Players share theories and tips while they play through.',
      'A spoiler-free approach: agree a rule in your group chat on what you will and will not discuss before everyone finishes. Use a spoiler channel or a shared notes post for the rest.',
      ['Control: Resonant'], '4d ago', Icons.psychology),
  NewsItem('n19', 'Co-op / Party', 'Helldivers 2 and Marvel Rivals: team-play basics',
      'Coordinated teams survive longer and clear objectives faster.',
      'Name your roles before the drop, share your stratagems or ultimates out loud, and stay inside a few metres of each other. Friendly fire is a coordination problem, not a skill problem.',
      ['Helldivers 2', 'Marvel Rivals'], '5d ago', Icons.diversity_3),
  NewsItem('n20', 'Co-op / Party', 'Rocket League: rotation 101 for new teammates',
      'Clear rotations stop two players going for the same ball.',
      'Agree a simple rule: first player challenges, second covers, third stays back. Calling "mine" and "I\'m back" keeps rotations tidy, even in casual playlists.',
      ['Rocket League'], '5d ago', Icons.sports_score),
  NewsItem('n21', 'Esports', 'Esports: how to join a team without a pro background',
      'Amateur leagues and community scrims are the usual entry point.',
      'Start in open scrims, record your gameplay, and show you can turn up on time. Teams value reliability and communication as much as raw rank.',
      ['Valorant', 'Counter-Strike 2'], '5d ago', Icons.emoji_events),
  NewsItem('n22', 'Esports', 'Dota 2 and Rainbow Six Siege: scrim etiquette',
      'Be on time, bring a plan, and give feedback after the match.',
      'Confirm the time, the format and the map pool ahead of time. A quick five-minute debrief after each scrim is worth more than another game.',
      ['Dota 2', 'Rainbow Six Siege'], '6d ago', Icons.groups_2),
  NewsItem('n23', 'Releases', 'Halo: Campaign Evolved: co-op campaign night ideas',
      'Plan a regular night to finish the campaign together.',
      'Pick one night a week, set a chapter target and rotate who chooses the difficulty. Finishing a campaign with friends beats finishing it alone.',
      ['Halo: Campaign Evolved'], '6d ago', Icons.nightlight),
  NewsItem('n24', 'Co-op / Party', 'Lethal Company and Dead by Daylight: horror night picks',
      'Nothing bonds a squad like panic in voice chat.',
      'Keep sessions short, agree on a word for "retreat", and rotate who takes risky jobs. Streams and recordings are great for the highlights.',
      ['Lethal Company', 'Dead by Daylight'], '1w ago', Icons.sentiment_very_dissatisfied),
];

/// Game picked from "News about this game" (null = all games).
final newsGame = ValueNotifier<String?>(null);
final newsMine = ValueNotifier<bool>(false);

DateTime? parseRelease(String s) {
  final m = RegExp(r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$').firstMatch(s);
  if (m == null) return null;
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final i = mo.indexOf(m.group(1)!);
  if (i < 0) return null;
  return DateTime(int.parse(m.group(3)!), i + 1, int.parse(m.group(2)!));
}

String releaseIn(String when) {
  final d = parseRelease(when);
  if (d == null) return when;
  final n = DateTime.now();
  final days = d.difference(DateTime(n.year, n.month, n.day)).inDays;
  if (days < 0) return 'Out now';
  if (days == 0) return 'Releases today';
  if (days == 1) return 'Tomorrow';
  return 'in $days days';
}

Player? playerByTag(String tag) {
  for (final p in kPlayers) {
    if (p.tag == tag) return p;
  }
  return null;
}

void openNews(BuildContext c, NewsItem n) => Navigator.push(c, MaterialPageRoute(builder: (_) => NewsDetailScreen(n)));

class NewsCard extends StatelessWidget {
  final NewsItem n;
  const NewsCard(this.n, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Pressable(child: Material(
          color: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openNews(context, n),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 88, height: 88, child: n.games.isEmpty ? const SizedBox() : CoverImage(n.games.first, compact: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      infoChip(n.cat, icon: n.icon, color: kAccent),
                      Text(n.ago, style: const TextStyle(fontSize: 12, color: kMuted)),
                    ]),
                    const SizedBox(height: 6),
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                    const SizedBox(height: 4),
                    Text(n.summary, style: const TextStyle(color: kMuted, fontSize: 13.5)),
                  ]),
                ),
              ]),
            ),
          ),
        )),
      );
}

class NewsDetailScreen extends StatelessWidget {
  final NewsItem n;
  const NewsDetailScreen(this.n, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('News')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (n.games.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 190, child: CoverImage(n.games.first))),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                infoChip(n.cat, icon: n.icon, color: kAccent),
                Text(n.ago, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ]),
              const SizedBox(height: 10),
              Text(n.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(n.body, style: const TextStyle(fontSize: 15.5, height: 1.5)),
              const SizedBox(height: 16),
              const Text('Related games', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in n.games) ActionChip(avatar: const Icon(Icons.people, size: 16), label: Text('Find teammates: $g'), onPressed: () => openGame(context, g)),
              ]),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: S,
                builder: (_, __) => Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final g in n.games)
                    FilterChip(
                      selected: S.me?.followed.contains(g) ?? false,
                      avatar: const Icon(Icons.favorite, size: 16),
                      label: Text((S.me?.followed.contains(g) ?? false) ? 'Following $g' : 'Follow $g'),
                      onSelected: (_) => S.toggleFollow(g),
                    ),
                ]),
              ),
              if ((S.me?.showBuyLinks ?? true) && n.games.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(onPressed: () => showBuySheet(context, n.games.first), icon: const Icon(Icons.shopping_bag_outlined, size: 18), label: Text('Where to buy ${n.games.first}')),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 18, color: kMuted),
                  SizedBox(width: 8),
                  Expanded(child: Text('Sample article written for the SquadUp demo — not a live news headline.', style: TextStyle(color: kMuted, fontSize: 12.5))),
                ]),
              ),
            ]),
          ),
        ),
      );
}

// ───────────────────────── News tab ─────────────────────────
class NewsTab extends StatefulWidget {
  NewsTab({super.key});
  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  final q = TextEditingController();
  final cats = <String>{};

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([S, newsGame, newsMine]),
        builder: (context, _) {
          final me = S.me;
          final mineOn = newsMine.value;
          final game = newsGame.value;
          final t = q.text.trim().toLowerCase();
          final mine = <String>{...?me?.games, ...?me?.followed};
          final list = kNews.where((n) {
            if (cats.isNotEmpty && !cats.contains(n.cat)) return false;
            if (game != null && !n.games.contains(game)) return false;
            if (mineOn && !n.games.any(mine.contains)) return false;
            if (t.isNotEmpty && !('${n.title} ${n.summary} ${n.games.join(' ')}').toLowerCase().contains(t)) return false;
            return true;
          }).toList();
          final gamesInNews = <String>{for (final n in kNews) ...n.games}.toList()..sort();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                pageTitle('News'),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 18, color: kMuted),
                    SizedBox(width: 8),
                    Expanded(child: Text('Demo news: these are sample stories for the prototype, not live headlines. A real news feed can be plugged in later.', style: TextStyle(color: kMuted, fontSize: 12.5))),
                  ]),
                ),
                outLabel(
                  'Search news',
                  TextField(
                    controller: q,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by title or game…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: q.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(q.clear),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                outLabel(
                  'Game type',
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ChoiceChip(label: const Text('All'), selected: cats.isEmpty, onSelected: (_) => setState(cats.clear)),
                    for (final c in kNewsCats)
                      FilterChip(
                        label: Text(c),
                        selected: cats.contains(c),
                        onSelected: (v) => setState(() => v ? cats.add(c) : cats.remove(c)),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
                PickField(
                  label: 'Game',
                  value: game ?? 'All games',
                  options: ['All games', ...gamesInNews],
                  onChanged: (v) => newsGame.value = v == 'All games' ? null : v,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    avatar: const Icon(Icons.favorite, size: 16),
                    label: const Text('Only my games & followed'),
                    selected: mineOn,
                    onSelected: (v) => newsMine.value = v,
                  ),
                ),
                const SizedBox(height: 14),
                Text('${list.length} stor${list.length == 1 ? 'y' : 'ies'}', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Text('No stories match these filters.', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
                for (final n in list) NewsCard(n),
              ]),
            ),
          );
        },
      );
}

// ───────────────────────── Home dashboard ─────────────────────────
class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  Widget _stat(IconData i, String v, String l, VoidCallback t) => Expanded(
        child: Pressable(child: Material(
          color: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: t,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(i, color: kAccent),
                const SizedBox(height: 8),
                Text(v, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(l, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ]),
            ),
          ),
        )),
      );

  Widget _person(BuildContext context, Player p, String sub, List<Widget> actions) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          InkWell(borderRadius: BorderRadius.circular(30), onTap: () => openPlayer(context, p), child: Avatar(p.avatar, status: p.status)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.tag, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
          ...actions,
        ]),
      );

  Widget _empty(String t) => Text(t, style: const TextStyle(color: kMuted));

  Widget _sub(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final me = S.me;
          if (me == null) return const SizedBox();
          final name = me.first.isNotEmpty ? me.first : me.username;
          final online = [for (final t in S.friends) if (playerByTag(t) != null) playerByTag(t)!];
          final onlineNow = online.where((p) => p.status == 'online').length;

          final sentTags = S.invited.where((t) => !S.friends.contains(t)).toList();
          final friendReqs = Sec(
            'Friend requests',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (S.incomingFriendReqs.isEmpty && sentTags.isEmpty) _empty('No pending requests.'),
              if (S.incomingFriendReqs.isNotEmpty) _sub('Wants to join your squad'),
              for (final p in S.incomingFriendReqs)
                _person(context, p, '${p.role} · ${p.platform}', [
                  IconButton(tooltip: 'Accept', onPressed: () => S.acceptFriend(p), icon: const Icon(Icons.check_circle, color: kAccent)),
                  IconButton(tooltip: 'Decline', onPressed: () => S.declineFriend(p), icon: const Icon(Icons.cancel_outlined, color: kMuted)),
                ]),
              if (sentTags.isNotEmpty) _sub('Sent by you · waiting for a reply'),
              for (final t in sentTags)
                if (playerByTag(t) != null)
                  _person(context, playerByTag(t)!, 'Pending…', [
                    IconButton(tooltip: 'Cancel request', onPressed: () => S.cancelInvite(playerByTag(t)!), icon: const Icon(Icons.close, color: kMuted)),
                  ]),
            ]),
          );

          final toApprove = S.manageableGroups.where((g) => g.requests.isNotEmpty).toList();
          final waiting = S.myPendingJoins;
          final groupReqs = Sec(
            'Group requests',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (toApprove.isEmpty && waiting.isEmpty) _empty('Nothing waiting on you or anyone else.'),
              for (final g in toApprove) ...[
                _sub('Needs your approval · ${g.name}'),
                for (final r in List<Object>.of(g.requests))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.person_add_alt, color: kAccent),
                      const SizedBox(width: 12),
                      Expanded(child: Text(whoName(r), style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(tooltip: 'Approve', onPressed: () => S.approve(g, r, true), icon: const Icon(Icons.check_circle, color: kAccent)),
                      IconButton(tooltip: 'Decline', onPressed: () => S.approve(g, r, false), icon: const Icon(Icons.cancel_outlined, color: kMuted)),
                    ]),
                  ),
              ],
              if (waiting.isNotEmpty) _sub('Waiting for someone else to accept you'),
              for (final g in waiting)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.hourglass_top, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => openGroup(context, g),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Waiting for ${g.owner.name} (owner)', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                        ]),
                      ),
                    ),
                    IconButton(tooltip: 'Cancel request', onPressed: () => S.cancelJoin(g), icon: const Icon(Icons.close, color: kMuted)),
                  ]),
                ),
            ]),
          );

          final mine = S.groupsOf(me);
          final myGroups = Sec(
            'My groups',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (mine.isEmpty) _empty("You haven't joined a group yet."),
              for (final g in mine)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: kTeal, child: Icon(Icons.groups, color: Colors.white)),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${g.members.length} members · ${g.memberOf(me)!.role}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openGroup(context, g),
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(onPressed: () => goTab(4), icon: const Icon(Icons.explore_outlined), label: const Text('Browse groups')),
            ]),
            action: TextButton(onPressed: () => goTab(4), child: const Text('See all')),
          );

          final squad = Sec(
            'Squad online',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (online.isEmpty) _empty('Add friends from Find Team to see them here.'),
              for (final p in online)
                _person(context, p, p.status, [
                  IconButton(tooltip: 'Message', onPressed: () => openChat(context, S.startChat(p)), icon: const Icon(Icons.chat_bubble_outline, color: kAccent)),
                ]),
            ]),
          );

          final sug = ranked(kPlayers.where((p) => !S.friends.contains(p.tag) && !S.invited.contains(p.tag) && !S.incomingFriendReqs.contains(p))).take(3).toList();
          final suggested = Sec(
            'Suggested teammates',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (sug.isEmpty) _empty('No suggestions right now.'),
              for (final e in sug)
                _person(context, e.$1, '${e.$2}% match · ${e.$1.platform}', [
                  FilledButton(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => S.invite(e.$1),
                    child: const Text('Add'),
                  ),
                ]),
            ]),
            action: TextButton(onPressed: () => goTab(1), child: const Text('Find more')),
          );

          final feed = <(Group, Post)>[
            for (final g in mine)
              if (g.news.isNotEmpty) (g, g.news.first),
          ];
          final announcements = Sec(
            'Group announcements',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (feed.isEmpty) _empty('No announcements from your groups yet.'),
              for (final e in feed.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () => openGroup(context, e.$1),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e.$1.name} · ${whoName(e.$2.who)}', style: const TextStyle(color: kAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(e.$2.text),
                    ]),
                  ),
                ),
            ]),
          );

          final releases = kUpcoming.entries.toList();
          final upcoming = Sec(
            'Upcoming releases',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final e in releases)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 44, child: CoverImage(e.key, compact: true))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => openGame(context, e.key),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${e.value} · ${releaseIn(e.value)}', style: const TextStyle(color: Colors.amber, fontSize: 12.5)),
                        ]),
                      ),
                    ),
                    if (me.showBuyLinks) IconButton(tooltip: 'Pre-order', onPressed: () => showBuySheet(context, e.key), icon: const Icon(Icons.shopping_bag_outlined, color: kMuted)),
                    IconButton(
                      tooltip: me.followed.contains(e.key) ? 'Unfollow' : 'Follow',
                      onPressed: () => S.toggleFollow(e.key),
                      icon: Icon(me.followed.contains(e.key) ? Icons.favorite : Icons.favorite_border, color: me.followed.contains(e.key) ? Colors.pinkAccent : kMuted),
                    ),
                  ]),
                ),
            ]),
          );

          final followedGames = me.followed.toList()..sort();
          final followed = Sec(
            'Games you follow',
            followedGames.isEmpty
                ? _empty('Tap the heart on any game to follow it.')
                : Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in followedGames) ActionChip(avatar: const Icon(Icons.favorite, size: 16, color: Colors.pinkAccent), label: Text(g), onPressed: () => openGame(context, g)),
                  ]),
          );

          final checks = <(String, bool, VoidCallback)>[
            ('Add a bio', me.bio.trim().isNotEmpty, () => openMyProfile(context)),
            ('Upload a profile photo', me.avatarBytes != null, () => openMyProfile(context)),
            ('Link a gaming account', me.linked.values.any((v) => v), () => goTab(6)),
            ('Add at least 3 games', me.games.length >= 3, () => goTab(6)),
            ('Join a group', mine.isNotEmpty, () => goTab(4)),
            ('Add a squad mate', S.friends.isNotEmpty, () => goTab(1)),
          ];
          final done = checks.where((c) => c.$2).length;
          final Widget profile = done == checks.length
              ? const SizedBox()
              : Sec(
                  'Complete your profile',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: done / checks.length, minHeight: 8, color: kAccent)),
                    const SizedBox(height: 6),
                    Text('$done of ${checks.length} done', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                    for (final c in checks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(c.$2 ? Icons.check_circle : Icons.radio_button_unchecked, color: c.$2 ? kAccent : kMuted),
                        title: Text(c.$1, style: TextStyle(decoration: c.$2 ? TextDecoration.lineThrough : null)),
                        onTap: c.$2 ? null : c.$3,
                      ),
                  ]),
                );

          final newsPreview = Sec(
            'Latest news',
            Column(children: [for (final n in kNews.take(3)) NewsCard(n)]),
            action: TextButton(onPressed: () => goTab(5), child: const Text('See all')),
          );

          final left = <Widget>[friendReqs, groupReqs, myGroups, announcements, newsPreview];
          final right = <Widget>[profile, lfgSec(context), eventsSec(context), squad, suggested, upcoming, achievementsSec(me), followed];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(builder: (context, box) {
                final two = box.maxWidth >= 860;
                return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                  pageTitle('Welcome back, $name 👋'),
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _stat(Icons.chat_bubble_outline, '${S.totalUnread}', 'Unread messages', () => goTab(3)),
                      const SizedBox(width: 12),
                      _stat(Icons.person_add_alt, '${S.incomingFriendReqs.length}', 'Friend requests', () {}),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _stat(Icons.how_to_reg_outlined, '${S.pendingApprovals}', 'Group approvals', () {}),
                      const SizedBox(width: 12),
                      _stat(Icons.circle, '$onlineNow', 'Squad online', () {}),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (two)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(children: left)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(children: right)),
                    ])
                  else
                    Column(children: [...left, ...right]),
                ]);
              }),
            ),
          );
        },
      );
}

// ═════════════════════════ Launch-readiness features ═════════════════════════

// ───────────────────────── Store / affiliate links ─────────────────────────
/// Put your affiliate IDs here (leave '' until you have joined a programme). Replace {aff} in the
/// templates below with the exact format your affiliate programme gives you.
const kAffiliateIds = <String, String>{
  'Amazon': '', // e.g. your Amazon Associates tag
  'Green Man Gaming': '',
  'Fanatical': '',
};

/// (store name, icon, URL template). {game} = URL-encoded game name, {aff} = the ID above.
const kStores = <(String, IconData, String)>[
  ('Steam', Icons.computer, 'https://store.steampowered.com/search/?term={game}'),
  ('PlayStation Store', Icons.sports_esports, 'https://store.playstation.com/search/{game}'),
  ('Xbox / Microsoft Store', Icons.gamepad, 'https://www.xbox.com/search?q={game}'),
  ('Nintendo eShop', Icons.videogame_asset, 'https://www.nintendo.com/search/?q={game}'),
  ('Amazon', Icons.shopping_cart_outlined, 'https://www.amazon.com/s?k={game}&tag={aff}'),
  ('Green Man Gaming', Icons.storefront, 'https://www.greenmangaming.com/search?query={game}'),
  ('Fanatical', Icons.local_offer_outlined, 'https://www.fanatical.com/en/search?search={game}'),
];

const kAffiliateNote = 'Some store links are affiliate links. If you buy through them, SquadUp may earn a small commission at no extra cost to you. Prices are shown by the store, not by SquadUp.';

String storeUrl(String tmpl, String store, String game) =>
    tmpl.replaceAll('{game}', Uri.encodeComponent(game)).replaceAll('{aff}', Uri.encodeComponent(kAffiliateIds[store] ?? ''));

Future<void> openUrl(String u) async {
  try {
    final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    if (!ok) toast("Couldn't open the link");
  } catch (_) {
    toast("Couldn't open the link");
  }
}

void showBuySheet(BuildContext context, String game) {
  final soon = kUpcoming.containsKey(game);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.8),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(soon ? 'Pre-order $game' : 'Where to buy $game', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(soon ? 'Release: ${kUpcoming[game]} (dates can change). Check the store page for availability.' : 'Opens the store in your browser. Check the store for price and platform.',
                style: const TextStyle(color: kMuted, fontSize: 13)),
          ),
          for (final s in kStores)
            ListTile(
              leading: Icon(s.$2, color: kAccent),
              title: Text(s.$1),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                Navigator.pop(c);
                openUrl(storeUrl(s.$3, s.$1, game));
              },
            ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text(kAffiliateNote, style: const TextStyle(color: kMuted, fontSize: 12))),
        ]),
      ),
    ),
  );
}

// ───────────────────────── Legal ─────────────────────────
class LegalScreen extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;
  const LegalScreen(this.title, this.sections, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, size: 18, color: kMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Template text for the prototype. Have a qualified lawyer review it and fill in your company details before you publish the app.',
                        style: TextStyle(color: kMuted, fontSize: 12.5)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Last updated: November 2026', style: TextStyle(color: kMuted, fontSize: 12.5)),
              for (final s in sections) ...[
                const SizedBox(height: 18),
                Text(s.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(s.$2, style: const TextStyle(height: 1.5)),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ),
      );
}

void openTerms(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const LegalScreen('Terms & Conditions', kTerms)));
void openPrivacy(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const LegalScreen('Privacy Policy', kPrivacyPolicy)));
void openGuidelines(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const LegalScreen('Community Guidelines', kGuidelines)));

const kTerms = <(String, String)>[
  ('1. About SquadUp', 'SquadUp ("we", "us") is a free app that helps players find teammates, chat, join groups and read gaming news. By creating an account or using the app you agree to these Terms. If you do not agree, do not use SquadUp.'),
  ('2. Who can use SquadUp', 'You must be at least 13 years old. If you are under 18 you confirm that a parent or guardian allows you to use SquadUp. We may ask you to confirm your age and may remove accounts that give false information.'),
  ('3. Your account', 'Keep your login details secure and do not share your account. You are responsible for what happens under your account. Give accurate information and tell us if you think your account has been accessed without permission.'),
  ('4. Acceptable use', 'You agree to follow our Community Guidelines. You must not harass, threaten or discriminate against others, share illegal, sexual or violent content, impersonate people, cheat or sell accounts, spam, scrape data, or try to break or misuse the app.'),
  ('5. Your content', 'You keep ownership of what you post (messages, bio, group posts, photos). You give us a limited licence to store and display it so the app can work. You confirm you have the right to post it. We may remove content that breaks these Terms.'),
  ('6. Safety, reporting and blocking', 'You can report players, messages and groups and block other players at any time. We may warn, suspend or remove accounts that break these Terms. Never share passwords, payment details or your home address in chat.'),
  ('7. Linked game accounts and stats', 'You choose whether to link game accounts and who can see your stats. Stats come from the services you connect and may be delayed, incomplete or inaccurate. SquadUp is not affiliated with, endorsed by or sponsored by any game publisher or platform. Game names and logos belong to their owners.'),
  ('8. Store links and affiliate disclosure', 'SquadUp may show links to online stores. Some are affiliate links, which means we may earn a commission if you buy, at no extra cost to you. Purchases are made with the store, under its terms. We do not control store prices or stock.'),
  ('9. Availability and changes', 'SquadUp is provided "as is". We try to keep it running but cannot promise it will always be available or error-free. We may change or stop features, and we may update these Terms. If a change is important we will tell you in the app.'),
  ('10. Liability', 'To the extent the law allows, we are not responsible for loss caused by other users, third-party services or things outside our control. Nothing in these Terms limits liability that cannot legally be limited, such as for death or personal injury caused by negligence or for fraud.'),
  ('11. Ending your account', 'You can delete your account at any time in Settings. We may suspend or close accounts that break these Terms. Some information may be kept where the law requires it.'),
  ('12. Contact and governing law', 'Contact us at support@squadup.example. [Add your company name, address and governing law/country here before launch.]'),
];

const kPrivacyPolicy = <(String, String)>[
  ('1. Who we are', 'SquadUp is the controller of your personal data. Contact: privacy@squadup.example. [Add your company name and registered address before launch.]'),
  ('2. What we collect', 'Account details (name, email, username, date of birth, country, gender, optional phone), your profile (bio, games, availability, avatar or photo), content you create (messages, group posts, looking-for-group posts, events, reports), linked game account details and stats you choose to connect, and basic technical data (device type, app version, crash information).'),
  ('3. How we use it', 'To run your account, match you with teammates, deliver chat and groups, show you relevant news and releases, keep the community safe (reports, blocks, moderation), send notifications you have chosen, and improve the app.'),
  ('4. Who can see your information', 'You control visibility for your gamertag, games, age, bio, groups and game stats (Public, Friends Only or Private). Messages are visible to the people in the conversation. We do not sell your personal data.'),
  ('5. Sharing', 'We use service providers (hosting, analytics, crash reporting, email) who process data for us. We may share information if the law requires it or to protect users\' safety. Store links may take you to third-party websites with their own privacy policies.'),
  ('6. Children and teens', 'SquadUp is not for children under 13. For users under 18 we recommend stricter privacy settings and we limit what is shown on the profile by default. Parents or guardians can contact us to ask about or delete a child\'s account.'),
  ('7. Your rights', 'Depending on where you live you may have the right to access, correct, download or delete your data, object to some processing and withdraw consent. You can download or delete your data in Settings, or contact us.'),
  ('8. Keeping data', 'We keep data while your account is active. When you delete your account we delete or anonymise your personal data, except where we must keep it by law or for safety (for example, records of serious reports).'),
  ('9. Security', 'We use reasonable measures to protect your data, but no service is completely secure. Use a strong, unique password.'),
  ('10. Changes', 'We may update this policy. We will tell you in the app if a change is important.'),
];

const kGuidelines = <(String, String)>[
  ('Be respectful', 'Treat everyone the way you want to be treated. Hate speech, discrimination, bullying and harassment are not allowed.'),
  ('Keep it safe', 'No threats, doxxing, sharing personal details, or encouraging self-harm. If someone is in danger, contact local emergency services.'),
  ('Keep it clean', 'No sexual content, graphic violence or illegal content. This applies to names, bios, photos, groups and chat.'),
  ('Play fair', 'No cheating, boosting for money, account selling or scams. Be honest about your rank and experience.'),
  ('No spam', 'Do not send repeated unwanted messages, advertise without permission or post misleading links.'),
  ('Protect younger players', 'Do not contact players you know or suspect are minors in an inappropriate way. We act quickly on reports involving young people.'),
  ('Report and block', 'Use Report if something is wrong and Block if you do not want someone to contact you. Reports are reviewed by our team.'),
  ('What happens if rules are broken', 'We may remove content, give a warning, suspend or permanently remove the account, depending on how serious it is.'),
];

// ───────────────────────── Help, support, feedback ─────────────────────────
const kFaq = <(String, String)>[
  ('How does SquadUp match me with players?', 'We compare shared games, how often you play each one, age range, region and availability to give each player a match score.'),
  ('Are game stats real?', 'In this version stats are sample data to show how profiles will look. Real stats need official game or platform APIs and your permission.'),
  ('Who can see my stats?', 'You decide in Settings → Privacy (Public, Friends Only or Private). You can also hide stats for individual games.'),
  ('How do I join a private group?', 'Open the group and send a request. The owner or an admin approves it. You can see pending requests on your Home page.'),
  ('How do I block or report someone?', 'Open their profile or chat and tap the menu (⋮). Choose Report or Block. Blocked players disappear from your search, chat and invites.'),
  ('How do I delete my account?', 'Settings → Account → Delete account. You can also download a copy of your data first.'),
  ('Why do some stores show affiliate links?', 'Some links are affiliate links. We may earn a small commission if you buy, at no extra cost to you. You can hide store links in Settings.'),
  ('Is SquadUp free?', 'Yes. SquadUp is free to use.'),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & FAQ')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              for (final f in kFaq)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(f.$2, style: const TextStyle(color: kMuted, height: 1.4))],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: bigBtn(),
                onPressed: () => openAssistant(context),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Ask the SquadUp Assistant'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSupportScreen())),
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact support'),
              ),
            ]),
          ),
        ),
      );
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});
  @override
  State<ContactSupportScreen> createState() => _ContactSupportState();
}

class _ContactSupportState extends State<ContactSupportScreen> {
  String topic = 'Account problem';
  final msg = TextEditingController();
  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Contact support')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              PickField(label: 'Topic', value: topic, options: const ['Account problem', 'Report a bug', 'Safety concern', 'Privacy request', 'Something else'], onChanged: (v) => setState(() => topic = v)),
              const SizedBox(height: 14),
              outLabel('Message', TextField(controller: msg, maxLines: 6, maxLength: 1000)),
              const SizedBox(height: 8),
              FilledButton(
                style: bigBtn(),
                onPressed: () {
                  if (msg.text.trim().isEmpty) {
                    toast('Please write a message');
                    return;
                  }
                  Navigator.pop(context);
                  toast('Message sent (demo). Real support needs an email or ticket service.');
                },
                child: const Text('Send'),
              ),
            ]),
          ),
        ),
      );
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackState();
}

class _FeedbackState extends State<FeedbackScreen> {
  int stars = 0;
  final msg = TextEditingController();
  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Send feedback')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              outLabel(
                'How are you finding SquadUp?',
                Row(children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(onPressed: () => setState(() => stars = i), icon: Icon(i <= stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 32)),
                ]),
              ),
              const SizedBox(height: 8),
              outLabel('Tell us more (optional)', TextField(controller: msg, maxLines: 5, maxLength: 800)),
              const SizedBox(height: 8),
              FilledButton(
                style: bigBtn(),
                onPressed: () {
                  Navigator.pop(context);
                  toast('Thanks for your feedback! (demo)');
                },
                child: const Text('Submit'),
              ),
            ]),
          ),
        ),
      );
}

// ───────────────────────── Email verification ─────────────────────────
class VerifyEmailScreen extends StatefulWidget {
  final bool onboarding;
  const VerifyEmailScreen({super.key, this.onboarding = true});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmailScreen> {
  final code = TextEditingController();
  String? err;
  static const demoCode = '123456';
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void done() {
    if (widget.onboarding) {
      goTo(context, const WelcomeFlow());
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
        title: 'Verify your email',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: kAccent),
          const SizedBox(height: 16),
          Text('We sent a 6-digit code to ${S.me?.email ?? 'your email'}.', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Demo mode: no email is really sent. Use code 123456.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          outLabel('Verification code', TextField(controller: code, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(errorText: err))),
          const SizedBox(height: 8),
          FilledButton(
            style: bigBtn(),
            onPressed: () {
              if (code.text.trim() != demoCode) {
                setState(() => err = 'That code is not right');
                return;
              }
              S.me?.emailVerified = true;
              S.touch();
              toast('Email verified');
              done();
            },
            child: const Text('Verify'),
          ),
          TextButton(onPressed: () => toast('A new code was sent (demo)'), child: const Text('Resend code')),
          TextButton(onPressed: done, child: Text(widget.onboarding ? 'Verify later' : 'Cancel')),
        ]),
      );
}

// ───────────────────────── Safety: report / block / mute ─────────────────────────
const kReportReasons = ['Harassment or bullying', 'Hate speech', 'Spam or scam', 'Inappropriate content', 'Cheating', 'Might be under 13', 'Impersonation', 'Other'];

void showReportSheet(BuildContext context, String kind, String name) {
  var reason = kReportReasons.first;
  final note = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Report $kind'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PickField(label: 'Reason', value: reason, options: kReportReasons, onChanged: (v) => set(() => reason = v)),
              const SizedBox(height: 14),
              outLabel('Details (optional)', TextField(controller: note, maxLines: 3, maxLength: 300)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              S.reports.add('$kind: $name — $reason');
              Navigator.pop(d);
              toast('Report sent. Thank you for helping keep SquadUp safe.');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}

class PlayerMenu extends StatelessWidget {
  final Player p;
  final Chat? chat;
  const PlayerMenu(this.p, {super.key, this.chat});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'More options',
        onSelected: (v) async {
          if (v == 'report') {
            showReportSheet(context, 'player', p.tag);
          } else if (v == 'mute') {
            chat!.muted = !chat!.muted;
            S.touch();
            toast(chat!.muted ? 'Chat muted' : 'Chat unmuted');
          } else if (v == 'block') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text('Block ${p.tag}?'),
                content: const Text('They will be removed from your squad and chats, and hidden from your search and invites. You can unblock them in Settings.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Block')),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              S.block(p);
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'report', child: Text('Report player')),
          if (chat != null) PopupMenuItem(value: 'mute', child: Text(chat!.muted ? 'Unmute chat' : 'Mute chat')),
          const PopupMenuItem(value: 'block', child: Text('Block player')),
        ],
      );
}

extension SafetyActions on AppState {
  void block(Player p) {
    blocked.add(p.tag);
    friends.remove(p.tag);
    invited.remove(p.tag);
    incomingFriendReqs.remove(p);
    chats.removeWhere((c) => c.p == p);
    touch();
    toast('Blocked ${p.tag}');
  }

  void unblock(String tag) {
    blocked.remove(tag);
    touch();
    toast('Unblocked $tag');
  }
}

// ───────────────────────── Game stats (sample data) ─────────────────────────
String statsVisOf(Player p) => p.priv['Game stats'] ?? const ['Public', 'Public', 'Friends Only', 'Private'][p.tag.length % 4];
bool statsVisible(Player p) {
  final v = statsVisOf(p);
  return v == 'Public' || (v == 'Friends Only' && S.friends.contains(p.tag));
}

List<(String, String)> gameStats(String game, String key) {
  final h = (key + game).codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  int r(int lo, int hi, int salt) => lo + ((h >> (salt % 11)) + salt * 7919) % (hi - lo + 1);
  final g = game.toLowerCase();
  const ranks = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master'];
  if (g.contains('rocket league')) {
    final w = r(60, 1500, 1);
    return [('Wins', '$w'), ('Goals', '${w * r(12, 20, 2) ~/ 10}'), ('Saves', '${w * r(6, 14, 3) ~/ 10}'), ('MMR', '${r(600, 1700, 4)}'), ('Rank', ranks[r(0, 5, 5)])];
  }
  if (RegExp(r'fc \d|fifa|madden|nba|ea sports').hasMatch(g)) {
    final m = r(80, 900, 1);
    final w = m * r(42, 68, 2) ~/ 100;
    return [('Matches', '$m'), ('Wins', '$w'), ('Win rate', '${(w * 100 / m).round()}%'), ('Division', 'Div ${r(1, 10, 3)}'), ('Goals / pts', '${w * r(15, 30, 4) ~/ 10}')];
  }
  if (RegExp(r'f1|forza|gran turismo|assetto|iracing').hasMatch(g)) {
    final w = r(5, 140, 1);
    return [('Race wins', '$w'), ('Podiums', '${w + r(10, 90, 2)}'), ('Pole positions', '${w * r(4, 9, 3) ~/ 10}'), ('Clean-race rating', '${r(70, 99, 4)}%')];
  }
  if (RegExp(r'tekken|street fighter|smash|mortal|fighter').hasMatch(g)) {
    final m = r(100, 1500, 1);
    final w = m * r(44, 66, 2) ~/ 100;
    return [('Wins', '$w'), ('Win rate', '${(w * 100 / m).round()}%'), ('Best streak', '${r(3, 25, 3)}'), ('Rank', ranks[r(0, 5, 4)])];
  }
  if (RegExp(r'call of duty|apex|valorant|counter-strike|overwatch|rivals|rainbow|halo|battlefield|destiny|pubg|helldivers|splitgate|deadlock|gears|warzone|fortnite').hasMatch(g)) {
    final w = r(40, 1800, 1);
    final m = w * r(19, 40, 2) ~/ 10;
    return [
      ('K/D', (r(80, 260, 3) / 100).toStringAsFixed(2)),
      ('Wins', '$w'),
      ('Matches', '$m'),
      ('Win rate', '${(w * 100 / m).round()}%'),
      ('Headshots', '${r(8, 45, 4)}%'),
      ('Rank', ranks[r(0, 5, 5)]),
    ];
  }
  return [('Hours played', '${r(20, 1400, 1)}'), ('Achievements', '${r(5, 80, 2)}'), ('Level', '${r(5, 150, 3)}'), ('Last played', '${r(1, 28, 4)} days ago')];
}

class GameStatsCard extends StatelessWidget {
  final String game, seed;
  const GameStatsCard(this.game, this.seed, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [gameThumb(game), const SizedBox(width: 8), Expanded(child: Text(game, style: const TextStyle(fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in gameStats(game, seed))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(s.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kAccent)),
                  Text(s.$1, style: const TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
          ]),
        ]),
      );
}

const kStatsNote = 'Sample data for the demo. Real stats need official platform APIs and your permission.';

Widget playerStatsSec(Player p) {
  if (!statsVisible(p)) {
    return Sec('Game stats', lockedRow(statsVisOf(p) == 'Private' ? 'Game stats are private' : 'Game stats are visible to friends only'));
  }
  return Sec(
    'Game stats',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(kStatsNote, style: TextStyle(color: kMuted, fontSize: 12)),
      const SizedBox(height: 10),
      for (final g in p.games.take(4)) GameStatsCard(g, p.tag),
    ]),
  );
}

Widget myStatsSec(Profile me) {
  final linked = me.linked.values.any((v) => v);
  return Sec(
    'My game stats',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PickField(
        label: 'Who can see my game stats',
        value: me.privacy['Game stats'] ?? 'Public',
        options: kVis,
        onChanged: (v) {
          me.privacy['Game stats'] = v;
          S.update();
        },
      ),
      const SizedBox(height: 10),
      if (!linked)
        const Text('Link a gaming account (above) to show your stats on your profile.', style: TextStyle(color: kMuted))
      else ...[
        const Text(kStatsNote, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 6),
        for (final g in me.games) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Show $g stats'),
            value: !me.hideStats.contains(g),
            onChanged: (v) {
              v ? me.hideStats.remove(g) : me.hideStats.add(g);
              S.update();
            },
          ),
          if (!me.hideStats.contains(g)) GameStatsCard(g, me.username),
        ],
      ],
    ]),
  );
}

// ───────────────────────── Commendations & achievements ─────────────────────────
const kCommends = ['Friendly', 'Great communicator', 'Team player', 'Skilled', 'Always on time'];

extension CommendActions on AppState {
  int commendCount(Player p, String r) => (p.tag.length * 7 + r.length * 3) % 12 + (commends['${p.tag}|$r'] ?? 0);
  bool commended(Player p, String r) => myCommended.contains('${p.tag}|$r');
  void commend(Player p, String r) {
    final k = '${p.tag}|$r';
    if (myCommended.remove(k)) {
      commends[k] = (commends[k] ?? 1) - 1;
    } else {
      myCommended.add(k);
      commends[k] = (commends[k] ?? 0) + 1;
      toast('You commended ${p.tag}: $r');
      Timer(const Duration(seconds: 9), () => pushNotice('Commendations', Icons.thumb_up_alt, '${p.tag} commended you back', 'For: $r', color: Colors.pinkAccent, tab: 2));
    }
    touch();
  }
}

Widget commendSec(Player p) => Sec(
      'Commendations',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Played with them? Tap to commend. Tap again to undo.', style: TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in kCommends)
            FilterChip(
              label: Text('$r · ${S.commendCount(p, r)}'),
              selected: S.commended(p, r),
              onSelected: (_) => S.commend(p, r),
            ),
        ]),
      ]),
    );

List<(IconData, String, String, bool)> achievements(Profile me) => [
      (Icons.handshake_outlined, 'First squad mate', 'Add a friend', S.friends.isNotEmpty),
      (Icons.groups, 'Group founder', 'Create a group', S.groups.any((g) => g.memberOf(me)?.role == 'owner')),
      (Icons.diversity_3, 'Social butterfly', 'Have 5 squad mates', S.friends.length >= 5),
      (Icons.collections_bookmark, 'Game collector', 'Add 5 games', me.games.length >= 5),
      (Icons.verified, 'Verified', 'Verify your email', me.emailVerified),
      (Icons.link, 'Connected', 'Link a gaming account', me.linked.values.any((v) => v)),
      (Icons.campaign, 'Squad caller', 'Post a looking-for-group', S.lfg.any((l) => identical(l.who, me))),
      (Icons.event_available, 'Organiser', 'Host an event', S.events.any((e) => identical(e.host, me))),
    ];

Widget achievementsSec(Profile me) {
  final list = achievements(me);
  final n = list.where((a) => a.$4).length;
  return Sec(
    'Achievements',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$n of ${list.length} unlocked', style: const TextStyle(color: kMuted, fontSize: 12.5)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in list)
          Tooltip(
            message: a.$3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: a.$4 ? kAccent.withAlpha(40) : kField,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: a.$4 ? kAccent : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(a.$4 ? a.$1 : Icons.lock_outline, size: 16, color: a.$4 ? kAccent : kMuted),
                const SizedBox(width: 6),
                Text(a.$2, style: TextStyle(fontSize: 13, color: a.$4 ? null : kMuted)),
              ]),
            ),
          ),
      ]),
    ]),
  );
}

// ───────────────────────── Looking for group ─────────────────────────
class LfgPost {
  final Object who;
  final String game, mode, text, voice;
  final int need;
  final DateTime t = DateTime.now();
  final Set<Object> joined = {};
  LfgPost(this.who, this.game, this.mode, this.need, this.text, {this.voice = ''});
}

List<LfgPost> _seedLfg() => [
      LfgPost(kPlayers[0], kPlayers[0].games.first, 'Ranked', 2, 'Need 2 for ranked tonight, Diamond lobbies. Mic on please.', voice: 'https://discord.gg/example'),
      LfgPost(kPlayers[4], 'EA Sports FC 27', 'Casual', 1, 'Pro Clubs, need one striker for the weekend.'),
      LfgPost(kPlayers[8], kPlayers[8].games.first, 'Casual', 3, 'Chill games, no pressure. All skill levels welcome.'),
      LfgPost(kPlayers[11], kPlayers[11].games.first, 'Tournament practice', 2, 'Scrims for our weekly tournament, bring your own strategy.'),
      LfgPost(kPlayers[3], kPlayers[3].games.first, 'Campaign / co-op', 1, 'Looking for a story co-op partner, UK evenings.'),
    ];

extension LfgActions on AppState {
  void postLfg(String game, String mode, int need, String text, String voice) {
    final u = me;
    if (u == null) return;
    lfg.insert(0, LfgPost(u, game, mode, need, text, voice: voice));
    touch();
    toast('Your looking-for-group post is live');
    Timer(const Duration(seconds: 8), simulateLfgReply);
  }

  void joinLfg(LfgPost l) {
    final u = me;
    if (u == null || identical(l.who, u)) return;
    l.joined.add(u);
    final w = l.who;
    if (w is Player) {
      final c = startChat(w);
      c.msgs.add(Msg('Hi! I saw your ${l.game} post — can I join?', true));
    }
    touch();
    toast('Request sent to ${whoName(l.who)}');
    if (w is Player) {
      Timer(const Duration(seconds: 7), () => pushNotice('LFG & matches', Icons.sports_esports, '${w.tag} accepted you', 'You are in for the ${l.game} session.', color: Colors.tealAccent, chat: chatWith(w)));
    }
  }

  void toggleRsvp(SquadEvent e) {
    final u = me;
    if (u == null) return;
    final joined = !e.going.remove(u);
    if (joined) e.going.add(u);
    touch();
    if (joined) {
      Timer(const Duration(seconds: 15), () {
        if (e.going.contains(u)) pushNotice('Event reminders', Icons.event, 'Event reminder', '${e.title} · ${e.game} · ${fmtWhen(e.when)}', color: Colors.orangeAccent, tab: 2);
      });
    }
  }

  void createEvent(String title, String game, DateTime when, {Group? group}) {
    final u = me;
    if (u == null) return;
    events.insert(0, SquadEvent(title, game, when, u, group: group)..going.add(u));
    touch();
    toast('Event created');
  }
}

String fmtWhen(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]} ${d.day} ${mo[d.month - 1]} · ${fmtTime(d)}';
}

String ago(DateTime t) {
  final m = DateTime.now().difference(t).inMinutes;
  if (m < 1) return 'just now';
  if (m < 60) return '${m}m ago';
  if (m < 1440) return '${m ~/ 60}h ago';
  return '${m ~/ 1440}d ago';
}

class LfgTile extends StatelessWidget {
  final LfgPost l;
  const LfgTile(this.l, {super.key});
  @override
  Widget build(BuildContext context) {
    final mine = identical(l.who, S.me);
    final joined = l.joined.any((j) => identical(j, S.me));
    final left = (l.need - l.joined.length).clamp(0, 99).toInt();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          whoAvatar(l.who),
          const SizedBox(width: 10),
          Expanded(child: Text('${whoName(l.who)} · ${ago(l.t)}', style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          infoChip(l.game, icon: Icons.sports_esports, color: kAccent),
          infoChip(l.mode, icon: Icons.flag_outlined),
          infoChip(left == 0 ? 'Full' : 'Needs $left', icon: Icons.person_add_alt),
        ]),
        const SizedBox(height: 8),
        Text(l.text),
        if (l.voice.isNotEmpty) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => openUrl(l.voice),
            child: Row(children: [
              const Icon(Icons.headset_mic_outlined, size: 16, color: kAccent),
              const SizedBox(width: 6),
              Expanded(child: Text('Voice chat: ${l.voice}', style: const TextStyle(color: kAccent, fontSize: 13))),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: mine
              ? const Text('Your post', style: TextStyle(color: kMuted))
              : FilledButton(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: joined || left == 0 ? null : () => S.joinLfg(l),
                  child: Text(joined ? 'Requested' : 'Join'),
                ),
        ),
      ]),
    );
  }
}

void showLfgDialog(BuildContext context) {
  final me = S.me;
  if (me == null) return;
  var game = me.games.isNotEmpty ? me.games.first : kSorted.first;
  var mode = 'Casual';
  var need = '2';
  final text = TextEditingController();
  final voice = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Looking for group'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PickField(label: 'Game', value: game, options: kSorted, onChanged: (v) => set(() => game = v)),
              const SizedBox(height: 14),
              PickField(label: 'Mode', value: mode, options: const ['Casual', 'Ranked', 'Tournament practice', 'Campaign / co-op'], onChanged: (v) => set(() => mode = v)),
              const SizedBox(height: 14),
              PickField(label: 'Players needed', value: need, options: const ['1', '2', '3', '4'], onChanged: (v) => set(() => need = v)),
              const SizedBox(height: 14),
              outLabel('What are you looking for?', TextField(controller: text, maxLines: 3, maxLength: 160)),
              const SizedBox(height: 4),
              outLabel('Voice chat link (optional)', TextField(controller: voice, keyboardType: TextInputType.url)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isEmpty) {
                toast('Add a short description');
                return;
              }
              S.postLfg(game, mode, int.parse(need), text.text.trim(), voice.text.trim());
              Navigator.pop(d);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    ),
  );
}

class LfgScreen extends StatelessWidget {
  const LfgScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Looking for group')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => showLfgDialog(context), icon: const Icon(Icons.add), label: const Text('Post')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
                for (final l in S.lfg.where((l) => !(l.who is Player && S.blocked.contains((l.who as Player).tag)))) LfgTile(l),
              ]),
            ),
          ),
        ),
      );
}

Widget lfgSec(BuildContext context) {
  final list = S.lfg.where((l) => !(l.who is Player && S.blocked.contains((l.who as Player).tag))).take(2).toList();
  return Sec(
    'Looking for group',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (list.isEmpty) const Text('No posts right now. Be the first!', style: TextStyle(color: kMuted)),
      for (final l in list) LfgTile(l),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: () => showLfgDialog(context), icon: const Icon(Icons.add), label: const Text('Post')),
        OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LfgScreen())), child: const Text('See all')),
      ]),
    ]),
  );
}

// ───────────────────────── Events ─────────────────────────
class SquadEvent {
  final String title, game;
  final DateTime when;
  final Object host;
  final Group? group;
  final Set<Object> going = {};
  SquadEvent(this.title, this.game, this.when, this.host, {this.group});
}

List<SquadEvent> _seedEvents() {
  final n = DateTime.now();
  DateTime at(int d, int h, int m) => DateTime(n.year, n.month, n.day + d, h, m);
  return [
    SquadEvent('Friday ranked night', 'Apex Legends', at(2, 20, 0), kPlayers[0]),
    SquadEvent('Pro Clubs league night', 'EA Sports FC 27', at(3, 19, 30), kPlayers[4]),
    SquadEvent('Weekend scrims', 'Valorant', at(5, 18, 0), kPlayers[11]),
  ];
}

Future<void> showEventDialog(BuildContext context, {Group? group}) async {
  final me = S.me;
  if (me == null) return;
  var game = group != null && group.games.isNotEmpty ? group.games.first : (me.games.isNotEmpty ? me.games.first : kSorted.first);
  var date = DateTime.now().add(const Duration(days: 1));
  var time = const TimeOfDay(hour: 19, minute: 0);
  final title = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Create event'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              outLabel('Event name', TextField(controller: title, maxLength: 50)),
              PickField(label: 'Game', value: game, options: group?.games ?? kSorted, onChanged: (v) => set(() => game = v)),
              const SizedBox(height: 14),
              outLabel(
                'Date and time',
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(fmtDate(date)),
                      onPressed: () async {
                        final x = await showDatePicker(context: d, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (x != null) set(() => date = x);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule, size: 16),
                      label: Text(time.format(d)),
                      onPressed: () async {
                        final x = await showTimePicker(context: d, initialTime: time);
                        if (x != null) set(() => time = x);
                      },
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) {
                toast('Give the event a name');
                return;
              }
              S.createEvent(title.text.trim(), game, DateTime(date.year, date.month, date.day, time.hour, time.minute), group: group);
              Navigator.pop(d);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

Widget eventsSec(BuildContext context) {
  final list = S.events.where((e) => e.when.isAfter(DateTime.now().subtract(const Duration(hours: 2))) && (e.group == null || e.group!.memberOf(S.me) != null)).toList()..sort((a, b) => a.when.compareTo(b.when));
  return Sec(
    'Upcoming events',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (list.isEmpty) const Text('No events yet. Create one for your squad.', style: TextStyle(color: kMuted)),
      for (final e in list.take(4))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            const Icon(Icons.event, color: kAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${e.game} · ${fmtWhen(e.when)}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                Text('${e.going.length} going · hosted by ${whoName(e.host)}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ]),
            ),
            e.going.any((g) => identical(g, S.me))
                ? FilledButton(style: FilledButton.styleFrom(visualDensity: VisualDensity.compact), onPressed: () => S.toggleRsvp(e), child: const Text('Going'))
                : OutlinedButton(style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact), onPressed: () => S.toggleRsvp(e), child: const Text('RSVP')),
          ]),
        ),
      const SizedBox(height: 4),
      OutlinedButton.icon(onPressed: () => showEventDialog(context), icon: const Icon(Icons.add), label: const Text('Create event')),
    ]),
  );
}

// ───────────────────────── Settings sections ─────────────────────────
final textScale = ValueNotifier<double>(1.0);

void showMyData(BuildContext context, Profile p) {
  final data = const JsonEncoder.withIndent('  ').convert({
    'name': '${p.first} ${p.last}',
    'username': p.username,
    'email': p.email,
    'phone': p.phone,
    'dateOfBirth': p.dob?.toIso8601String(),
    'country': p.country,
    'gender': p.gender,
    'bio': p.bio,
    'games': p.games,
    'followedGames': p.followed.toList(),
    'linkedAccounts': p.linked,
    'privacy': p.privacy,
    'squadMates': S.friends.toList(),
    'blockedPlayers': S.blocked.toList(),
  });
  showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: kCard,
      title: const Text('Your data'),
      content: SizedBox(width: 460, height: 360, child: SingleChildScrollView(child: SelectableText(data, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)))),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: data));
            toast('Copied to clipboard');
          },
          child: const Text('Copy'),
        ),
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close')),
      ],
    ),
  );
}

List<Widget> settingsMore(BuildContext context, Profile profile) {
  Widget link(IconData i, String t, VoidCallback f, {String? sub}) =>
      ListTile(contentPadding: EdgeInsets.zero, leading: Icon(i), title: Text(t), subtitle: sub == null ? null : Text(sub), trailing: const Icon(Icons.chevron_right), onTap: f);
  return [
    Sec(
      'Notification types',
      Column(children: [
        for (final k in profile.notif.keys.toList())
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(k),
            value: profile.notif[k]!,
            onChanged: (v) {
              profile.notif[k] = v;
              S.update();
            },
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: S.demoNext,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send a test notification (changes each tap)'),
          ),
        ),
      ]),
    ),
    Sec(
      'Safety',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Blocked players', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (S.blocked.isEmpty) const Text('You have not blocked anyone.', style: TextStyle(color: kMuted)),
        for (final t in S.blocked.toList())
          ListTile(contentPadding: EdgeInsets.zero, title: Text(t), trailing: TextButton(onPressed: () => S.unblock(t), child: const Text('Unblock'))),
        const Divider(),
        link(Icons.shield_outlined, 'Safety tips', () => showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Stay safe online'),
                content: const Text('• Never share passwords, payment details or your home address.\n• Keep chats on SquadUp until you trust someone.\n• Use Block and Report if anything feels wrong.\n• Be careful with links from people you do not know.\n• Players under 18: tell a parent or guardian if someone makes you uncomfortable.'),
                actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
              ),
            )),
        link(Icons.rule, 'Community Guidelines', () => openGuidelines(context)),
      ]),
    ),
    Sec(
      'Display & shopping',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ValueListenableBuilder<double>(
          valueListenable: textScale,
          builder: (_, v, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Text size: ${(v * 100).round()}%'),
            Slider(value: v, min: 0.85, max: 1.4, divisions: 11, onChanged: (x) => textScale.value = x),
          ]),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show "Where to buy" store links'),
          subtitle: const Text('Some are affiliate links'),
          value: profile.showBuyLinks,
          onChanged: (v) {
            profile.showBuyLinks = v;
            S.update();
          },
        ),
      ]),
    ),
    Sec(
      'Your data',
      Column(children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(profile.emailVerified ? Icons.verified : Icons.mark_email_unread_outlined, color: profile.emailVerified ? kAccent : null),
          title: Text(profile.emailVerified ? 'Email verified' : 'Verify your email'),
          subtitle: Text(profile.email),
          trailing: profile.emailVerified ? null : const Icon(Icons.chevron_right),
          onTap: profile.emailVerified ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen(onboarding: false))),
        ),
        link(Icons.download_outlined, 'Download my data', () => showMyData(context, profile)),
        link(Icons.devices_other, 'Log out of all devices', () {
          toast('Logged out everywhere (demo)');
          logout(context);
        }),
      ]),
    ),
    Sec(
      'Help & legal',
      Column(children: [
        link(Icons.smart_toy_outlined, 'Ask the SquadUp Assistant', () => openAssistant(context), sub: 'Questions, problems and feedback'),
        link(Icons.receipt_long_outlined, 'My reports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()))),
        if (S.isAdmin) link(Icons.admin_panel_settings_outlined, 'Team review (demo admin)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamReviewScreen()))),
        link(Icons.help_outline, 'Help & FAQ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
        link(Icons.support_agent, 'Contact support', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSupportScreen()))),
        link(Icons.rate_review_outlined, 'Send feedback', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
        link(Icons.description_outlined, 'Terms & Conditions', () => openTerms(context)),
        link(Icons.privacy_tip_outlined, 'Privacy Policy', () => openPrivacy(context)),
        link(Icons.storefront, 'Affiliate disclosure', () => showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Affiliate disclosure'),
                content: const Text(kAffiliateNote),
                actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
              ),
            )),
        link(Icons.info_outline, 'About SquadUp', () => showAboutDialog(
              context: context,
              applicationName: 'SquadUp',
              applicationVersion: kAppVersion,
              applicationIcon: const LogoIcon(size: 48),
              children: const [Text('Find your squad. Level up together.\n\nSquadUp is not affiliated with any game publisher or platform holder.')],
            )),
      ]),
    ),
  ];
}

// ═════════════════════════ SquadUp Assistant, feedback & team review ═════════════════════════

const kAppVersion = '1.0.0';

class FeedbackReport {
  final String id, category, severity, summary, steps, screen, platform;
  final DateTime t;
  final String from;
  String status;
  String note;
  FeedbackReport(this.id, this.category, this.severity, this.summary, this.steps, this.screen, this.platform, this.from,
      {this.status = 'Received', this.note = '', DateTime? t})
      : t = t ?? DateTime.now();
}

const kReportStatuses = ['Received', 'In review', 'Resolved', 'Ignored'];
const kReportCategories = ['Bug', 'Feature idea', 'Account issue', 'Safety concern', 'Other'];

List<FeedbackReport> _seedReports() => [
      FeedbackReport('SU-1001', 'Bug', 'Medium', 'Sample: group chat scrolls to the top after I send a message.', 'Open a group → Chat → send two messages.', 'Groups', 'android', 'NovaStrike',
          status: 'In review', t: DateTime.now().subtract(const Duration(days: 2))),
      FeedbackReport('SU-1002', 'Feature idea', 'n/a', 'Sample: add a dark-green theme option.', '', 'Settings', 'web', 'PixelPaladin', t: DateTime.now().subtract(const Duration(days: 1))),
      FeedbackReport('SU-1003', 'Account issue', 'High', "Sample: I didn't get my verification email.", 'Sign up → wait for the email.', 'Home', 'ios', 'KageRonin', t: DateTime.now().subtract(const Duration(hours: 5))),
    ];

String currentScreenName() => const ['Home (Games)', 'Find Team', 'Dashboard', 'Chats', 'Groups', 'News', 'Settings'][navIndex.value.clamp(0, 6).toInt()];
String platformName() => kIsWeb ? 'web' : defaultTargetPlatform.name;

extension FeedbackActions on AppState {
  bool get isAdmin => me?.username == 'demo';
  List<FeedbackReport> get myReports => me == null ? [] : feedback.where((f) => f.from == me!.username).toList();

  FeedbackReport submitReport(String category, String severity, String summary, String steps) {
    final r = FeedbackReport('SU-${1001 + feedback.length}', category, severity, summary, steps, currentScreenName(), platformName(), me?.username ?? 'guest');
    feedback.insert(0, r);
    touch();
    Timer(const Duration(seconds: 8), () => pushNotice('Safety & support', Icons.support_agent, 'Report received', 'Thanks! ${r.id} is now in review.', color: Colors.lightGreenAccent, tab: 6));
    return r;
  }
}

// ── Assistant "brain" ──
// This is the ONE place the app talks to the assistant. It is rule-based for the prototype.
// For a real AI, replace the body with a call to YOUR server, which calls the language-model API.
// Never put an API key inside the app.
class AssistantReply {
  final String text;
  final List<(String, int)> goto; // button label, tab to open (-1 = Help & FAQ screen)
  final List<String> quick;
  const AssistantReply(this.text, {this.goto = const [], this.quick = const []});
}

const _kb = <(List<String>, String, List<(String, int)>)>[
  (['match', 'score', 'algorithm', 'recommend', 'suggest teammate'], 'Your match score (0–100) compares shared games, how often you play each one, age range, region and availability. A higher score means a better fit. Add more games and keep your availability up to date to improve it.', [('Open Find Team', 1)]),
  (['stat', 'k/d', 'kd ', 'wins', 'win rate'], 'Game stats show on your profile once you link an account. In this version they are sample data. You choose who sees them (Public, Friends only or Private) in Settings → Privacy, and you can hide individual games on your profile.', [('Open Settings', 6)]),
  (['privacy', 'private', 'hide', 'visible', 'who can see', 'anonymous'], 'Go to Settings → Privacy to choose who can see your gamertag, games, age, bio and game stats. You can also use an anonymous gamertag and hide the groups you are in.', [('Open Settings', 6)]),
  (['block'], 'Open the player\'s profile or chat, tap the ⋮ menu and choose Block player. They disappear from your squad, chats, search and suggestions. You can unblock in Settings → Safety.', [('Open Settings', 6)]),
  (['delete account', 'delete my', 'remove my account', 'close my account'], 'Settings → Account → Delete account. You can use Settings → Your data → Download my data first if you want a copy.', [('Open Settings', 6)]),
  (['password', 'forgot', 'reset', "can't log", 'cant log', 'locked out', 'login'], 'To change your password go to Settings → Account → Change password. If you cannot log in, tap "Forgot password" on the login screen. If that does not work, I can send a report to the team.', [('Open Settings', 6)]),
  (['verify', 'verification', 'email code', 'confirm email'], 'Settings → Your data → Verify your email. In this demo the code is 123456 because no real email is sent. If a real code does not arrive, check spam, then tell me and I will send a report.', [('Open Settings', 6)]),
  (['group', 'clan', 'guild', 'private group', 'join request'], 'Browse and search groups in the Groups tab. Public groups join instantly. For private groups you send a request that the owner approves; pending requests show on your Home page. Owners can manage members, announcements and what outsiders can see.', [('Open Groups', 4)]),
  (['unread', 'mute', 'message', 'chat'], 'Open the Chats tab to see your conversations. The badge shows unread messages. In a chat tap ⋮ to mute, report or block. Muted chats do not add to your unread count.', [('Open Chats', 3)]),
  (['friend', 'squad mate', 'invite', 'request'], 'Send an invite from a player\'s card or profile. Pending requests, and requests sent to you, are on your Home page where you can accept, decline or cancel.', [('Open Dashboard', 2)]),
  (['news', 'headline'], 'The News tab has sample gaming stories you can filter by game type, by game, or by games you play and follow. In this version the stories are demo content, not live headlines.', [('Open News', 5)]),
  (['buy', 'purchase', 'store', 'affiliate', 'where to buy', 'pre-order', 'preorder'], 'Game pages have a Where to buy (or Pre-order) button that opens a store in your browser. Some links are affiliate links, so SquadUp may earn a small commission at no extra cost to you. You can hide store links in Settings → Display & shopping.', [('Open Home', 0)]),
  (['notification', 'bell', 'push', 'alert'], 'The bell icon at the top shows unread messages, friend requests and group requests. You can choose which notification types you get in Settings → Notification types.', [('Open Settings', 6)]),
  (['text size', 'font', 'accessib', 'dark mode', 'light mode', 'theme', 'too small'], 'Settings has a dark/light mode switch and a text-size slider under Display & shopping.', [('Open Settings', 6)]),
  (['lfg', 'looking for group', 'need players', 'need teammates'], 'On Home, use Looking for group to post what you need (game, mode, players, optional voice link), or join someone else\'s post.', [('Open Dashboard', 2)]),
  (['event', 'rsvp', 'schedule'], 'Create an event from the Upcoming events card on Home, and tap RSVP to join one.', [('Open Dashboard', 2)]),
  (['photo', 'avatar', 'picture', 'upload'], 'Settings → Account → Profile picture lets you upload a photo or choose an avatar. You can also tap your avatar on your profile.', [('Open Settings', 6)]),
  (['cost', 'price', 'pay', 'free', 'subscription'], 'SquadUp is free to use. There are no subscriptions.', []),
];

const _problemWords = ['bug', 'crash', 'broken', 'not working', "doesn't work", 'doesnt work', 'error', 'problem', 'issue', 'glitch', 'stuck', 'freez', 'wrong', 'feedback', 'suggest', 'idea', 'complain', 'report a', 'send a report', 'contact', 'support'];
const _safetyWords = ['harass', 'threat', 'abuse', 'bully', 'underage', 'under 13', 'stalk', 'scam', 'hack', 'hacked', 'doxx'];

Future<AssistantReply> askAssistant(String raw) async {
  await Future<void>.delayed(const Duration(milliseconds: 600));
  final t = ' ${raw.toLowerCase().trim()} ';
  bool has(List<String> w) => w.any((k) => t.contains(k));
  if (RegExp(r"\b(kill myself|suicide|self[- ]harm|end my life)\b").hasMatch(t)) {
    return const AssistantReply("I'm really sorry you're feeling this way. I can't help with this properly, but you deserve support. If you are in immediate danger please contact your local emergency services. In the UK you can call Samaritans on 116 123 at any time. If you are elsewhere, a local crisis line or someone you trust can help.");
  }
  if (has(_safetyWords)) {
    return const AssistantReply('That sounds serious. Please use Report on the player, message or group (⋮ menu) and Block them if you want no more contact. Never share passwords or personal details. If someone is in danger, contact local emergency services. I can also send a safety report to the team.',
        quick: ['Send a report'], goto: [('Community Guidelines', -2)]);
  }
  if (has(['hello', 'hi ', 'hey', 'good morning', 'good evening']) && t.trim().split(' ').length <= 3) {
    return const AssistantReply('Hi! I\'m the SquadUp Assistant. Ask me how something works, or tell me about a problem and I\'ll send it to the team.', quick: ['How does matching work?', 'Who can see my stats?', 'Report a problem']);
  }
  if (has(['my reports', 'report status', 'status of my'])) {
    return const AssistantReply('Here are the reports you have sent so far.', goto: [('Open My reports', -3)]);
  }
  for (final e in _kb) {
    if (e.$1.any((k) => t.contains(k))) {
      return AssistantReply(e.$2, goto: e.$3, quick: const ['That solved it', "That didn't help"]);
    }
  }
  if (has(_problemWords)) {
    return const AssistantReply('I can send that to the team for you.', quick: ['Send a report']);
  }
  return const AssistantReply("I'm not sure about that one. I can show the Help & FAQ, or send your question to the team so a person can look at it.", quick: ['Send a report'], goto: [('Help & FAQ', -1)]);
}

// ── Assistant screen ──
class _AMsg {
  final String text;
  final bool mine;
  final List<String> quick;
  final List<(String, int)> goto;
  _AMsg(this.text, this.mine, {this.quick = const [], this.goto = const []});
}

void openAssistant(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const AssistantScreen()));

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantState();
}

class _AssistantState extends State<AssistantScreen> {
  final msgs = <_AMsg>[];
  final input = TextEditingController();
  final sc = ScrollController();
  bool typing = false;
  String? flow; // null | category | describe | steps | severity | confirm
  String cat = '', summary = '', steps = '', sev = 'n/a';

  @override
  void initState() {
    super.initState();
    msgs.add(_AMsg("Hi! I'm the SquadUp Assistant. I can answer questions about the app, and send feedback or problems to the team. What do you need?", false,
        quick: const ['How does matching work?', 'Who can see my stats?', 'Report a problem', 'Send feedback', 'My reports']));
  }

  @override
  void dispose() {
    input.dispose();
    sc.dispose();
    super.dispose();
  }

  void scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });

  void say(String t, {List<String> quick = const [], List<(String, int)> goto = const []}) {
    msgs.add(_AMsg(t, false, quick: quick, goto: goto));
    typing = false;
    if (mounted) setState(() {});
    scrollDown();
  }

  void startReport({String? category}) {
    cat = category ?? '';
    summary = '';
    steps = '';
    sev = 'n/a';
    if (category == null) {
      flow = 'category';
      say('Sure. What kind of report is it?', quick: kReportCategories);
    } else {
      pickCategory(category);
    }
  }

  void pickCategory(String c) {
    cat = c;
    flow = 'describe';
    if (c == 'Safety concern') {
      say('If someone is in danger, contact local emergency services. For a specific player, message or group please also use Report in the ⋮ menu so it is reviewed quickly.\n\nTell me what happened and I will send it to the team too.');
    } else if (c == 'Feature idea') {
      say("Great, we love ideas. What would you like to see in SquadUp?");
    } else {
      say('Please describe what happened in a sentence or two.');
    }
  }

  Future<void> handle(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    input.clear();
    msgs.add(_AMsg(t, true));
    typing = true;
    setState(() {});
    scrollDown();
    final low = t.toLowerCase();

    // report flow
    if (flow != null) {
      if (low == 'cancel') {
        flow = null;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return say('No problem, I cancelled that report. Anything else?', quick: const ['Report a problem', 'Help & FAQ']);
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      switch (flow) {
        case 'category':
          final m = kReportCategories.where((c) => c.toLowerCase() == low).toList();
          if (m.isEmpty) return say('Please choose one of the options.', quick: kReportCategories);
          return pickCategory(m.first);
        case 'describe':
          summary = t;
          if (cat == 'Feature idea') {
            flow = 'confirm';
            return confirmCard();
          }
          flow = 'steps';
          return say('Thanks. What were you doing when it happened? Type the steps, or "skip".', quick: const ['skip']);
        case 'steps':
          steps = low == 'skip' ? '' : t;
          if (cat == 'Safety concern') {
            sev = 'High';
            flow = 'confirm';
            return confirmCard();
          }
          flow = 'severity';
          return say('How much is it affecting you?', quick: const ['Low', 'Medium', 'High']);
        case 'severity':
          final s = ['Low', 'Medium', 'High'].where((x) => x.toLowerCase() == low).toList();
          if (s.isEmpty) return say('Please choose Low, Medium or High.', quick: const ['Low', 'Medium', 'High']);
          sev = s.first;
          flow = 'confirm';
          return confirmCard();
        case 'confirm':
          if (low.contains('send')) {
            final r = S.submitReport(cat, sev, summary, steps);
            flow = null;
            return say('Thank you! Your report ${r.id} was sent. You can follow its status in My reports. Anything else?',
                quick: const ['My reports', 'Help & FAQ'], goto: const [('Open My reports', -3)]);
          }
          if (low.contains('edit')) {
            flow = 'describe';
            return say('OK, describe it again.');
          }
          return say('Choose Send report, Edit or Cancel.', quick: const ['Send report', 'Edit', 'Cancel']);
      }
    }

    // quick replies / intents
    if (low == 'report a problem' || low == 'send a report') return startReport();
    if (low == 'send feedback') return startReport(category: 'Feature idea');
    if (low == 'that solved it') return say('Great! Anything else I can help with?', quick: const ['Send feedback']);
    if (low == "that didn't help") return say('Sorry about that. Want me to send it to the team?', quick: const ['Send a report']);
    if (low == 'help & faq') {
      return say('Here you go.', goto: const [('Open Help & FAQ', -1)]);
    }
    final r = await askAssistant(t);
    say(r.text, quick: r.quick, goto: r.goto);
  }

  void confirmCard() => say(
        'Please check your report:\n\nType: $cat${sev == 'n/a' ? '' : '\nSeverity: $sev'}\nSummary: $summary${steps.isEmpty ? '' : '\nSteps: $steps'}\n\nAuto-added: app version $kAppVersion, screen "${currentScreenName()}", platform ${platformName()}. No chat content is attached.',
        quick: const ['Send report', 'Edit', 'Cancel'],
      );

  void go(int tab) {
    if (tab == -1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
    } else if (tab == -2) {
      openGuidelines(context);
    } else if (tab == -3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
      goTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Row(children: [Icon(Icons.support_agent, color: kAccent), SizedBox(width: 8), Text('SquadUp Assistant')]),
          actions: [IconButton(tooltip: 'My reports', icon: const Icon(Icons.receipt_long_outlined), onPressed: () => go(-3))],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length + (typing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == msgs.length) {
                      return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: Text('Assistant is typing…', style: TextStyle(color: kMuted))));
                    }
                    final m = msgs[i];
                    final last = i == msgs.length - 1 && !typing;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: m.mine ? kAccent : kCard, borderRadius: BorderRadius.circular(16)),
                          child: Text(m.text, style: TextStyle(color: m.mine ? Colors.white : null, height: 1.35)),
                        ),
                        if (!m.mine && last) ...[
                          if (m.goto.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(spacing: 8, runSpacing: 6, children: [
                                for (final g in m.goto) OutlinedButton.icon(onPressed: () => go(g.$2), icon: const Icon(Icons.open_in_new, size: 16), label: Text(g.$1)),
                              ]),
                            ),
                          if (m.quick.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(spacing: 8, runSpacing: 6, children: [
                                for (final q in m.quick) ActionChip(label: Text(q), onPressed: () => handle(q)),
                              ]),
                            ),
                        ],
                      ]),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: handle,
                        decoration: InputDecoration(hintText: flow == null ? 'Ask a question or describe a problem…' : 'Type your answer (or "cancel")…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: () => handle(input.text), icon: const Icon(Icons.send)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ── My reports ──
Color statusTone(String s) => s == 'Resolved' ? kAccent : (s == 'In review' ? Colors.amber : (s == 'Ignored' ? Colors.grey : Colors.lightBlueAccent));

class ReportTile extends StatelessWidget {
  final FeedbackReport r;
  final Widget? footer;
  const ReportTile(this.r, {super.key, this.footer});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(r.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            infoChip(r.category),
            if (r.severity != 'n/a') infoChip('Severity: ${r.severity}'),
            infoChip(r.status, color: statusTone(r.status)),
          ]),
          const SizedBox(height: 8),
          Text(r.summary),
          if (r.steps.isNotEmpty) ...[const SizedBox(height: 4), Text('Steps: ${r.steps}', style: const TextStyle(color: kMuted, fontSize: 13))],
          const SizedBox(height: 6),
          Text('${fmtWhen(r.t)} · from ${r.from} · screen ${r.screen} · ${r.platform} · v$kAppVersion', style: const TextStyle(color: kMuted, fontSize: 12)),
          if (r.note.isNotEmpty) ...[const SizedBox(height: 6), Text('Team note: ${r.note}', style: const TextStyle(fontSize: 13, color: kAccent))],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ]),
      );
}

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final list = S.myReports;
          return Scaffold(
            appBar: AppBar(title: const Text('My reports')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (list.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Text('You have not sent any reports yet. Ask the assistant to report a problem or send feedback.', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
                  for (final r in list) ReportTile(r),
                  const SizedBox(height: 8),
                  FilledButton.icon(style: bigBtn(), onPressed: () => openAssistant(context), icon: const Icon(Icons.support_agent), label: const Text('Ask the assistant')),
                ]),
              ),
            ),
          );
        },
      );
}

// ── Team review (demo admin only) ──
class TeamReviewScreen extends StatefulWidget {
  const TeamReviewScreen({super.key});
  @override
  State<TeamReviewScreen> createState() => _TeamReviewState();
}

class _TeamReviewState extends State<TeamReviewScreen> {
  String fCat = 'Any', fStatus = 'Any';

  Future<void> editNote(FeedbackReport r) async {
    final c = TextEditingController(text: r.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Note for ${r.id}'),
        content: outLabel('Team note (visible to the user)', TextField(controller: c, maxLines: 3, maxLength: 200)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      r.note = c.text.trim();
      S.touch();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final list = S.feedback.where((r) => (fCat == 'Any' || r.category == fCat) && (fStatus == 'Any' || r.status == fStatus)).toList();
          return Scaffold(
            appBar: AppBar(title: const Text('Team review (demo admin)')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('Demo only: a real review tool needs a backend and proper admin sign-in. Reports here are kept for this session only.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                  const SizedBox(height: 12),
                  PickField(label: 'Category', value: fCat, options: ['Any', ...kReportCategories], onChanged: (v) => setState(() => fCat = v)),
                  const SizedBox(height: 12),
                  PickField(label: 'Status', value: fStatus, options: ['Any', ...kReportStatuses], onChanged: (v) => setState(() => fStatus = v)),
                  const SizedBox(height: 12),
                  Text('${list.length} report${list.length == 1 ? '' : 's'}', style: const TextStyle(color: kMuted)),
                  const SizedBox(height: 8),
                  for (final r in list)
                    ReportTile(
                      r,
                      footer: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        for (final st in kReportStatuses)
                          ChoiceChip(
                            label: Text(st),
                            selected: r.status == st,
                            onSelected: (_) {
                              r.status = st;
                              S.touch();
                            },
                          ),
                        TextButton.icon(onPressed: () => editNote(r), icon: const Icon(Icons.edit_note), label: const Text('Note')),
                      ]),
                    ),
                ]),
              ),
            ),
          );
        },
      );
}

// ───────────────────────── In-app notification banners ─────────────────────────
final navKey = GlobalKey<NavigatorState>();

class AppNotice {
  final String id, title, body;
  final IconData icon;
  final Color color;
  final int? tab; // main tab to open when tapped
  final Chat? chat; // chat to open when tapped
  AppNotice(this.id, this.icon, this.color, this.title, this.body, {this.tab, this.chat});
}

final notices = ValueNotifier<List<AppNotice>>([]);
const kNoticeSeconds = 5;

/// Shows a banner in the top corner for a few seconds. [category] must match a key in Profile.notif
/// so the user's notification settings are respected.
void pushNotice(String category, IconData icon, String title, String body, {Color color = kAccent, int? tab, Chat? chat}) {
  final u = S.me;
  if (u != null && u.notif[category] == false) return;
  final n = AppNotice('${DateTime.now().microsecondsSinceEpoch}', icon, color, title, body, tab: tab, chat: chat);
  notices.value = [n, ...notices.value].take(3).toList();
  Timer(const Duration(seconds: kNoticeSeconds), () => dismissNotice(n.id));
}

void dismissNotice(String id) {
  if (notices.value.any((n) => n.id == id)) notices.value = notices.value.where((n) => n.id != id).toList();
}

void _openNotice(AppNotice n) {
  dismissNotice(n.id);
  final nav = navKey.currentState;
  final ctx = navKey.currentContext;
  if (nav == null || ctx == null) return;
  if (n.chat != null && S.chats.contains(n.chat)) {
    nav.popUntil((r) => r.isFirst);
    openChat(ctx, n.chat!);
  } else if (n.tab != null) {
    nav.popUntil((r) => r.isFirst);
    goTab(n.tab!);
  }
}

class NoticeLayer extends StatelessWidget {
  const NoticeLayer({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<AppNotice>>(
        valueListenable: notices,
        builder: (context, list, _) {
          if (list.isEmpty) return const SizedBox.shrink();
          final narrow = MediaQuery.of(context).size.width < 520;
          return SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: narrow ? double.infinity : 380),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [for (final n in list) NoticeCard(n, key: ValueKey(n.id))]),
                ),
              ),
            ),
          );
        },
      );
}

class NoticeCard extends StatelessWidget {
  final AppNotice n;
  const NoticeCard(this.n, {super.key});
  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey('d${n.id}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => dismissNotice(n.id),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, -24 * (1 - v)), child: child)),
          child: Semantics(
            liveRegion: true,
            label: '${n.title}. ${n.body}',
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: n.color.withAlpha(90)),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                onTap: () => _openNotice(n),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 6, 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: n.color.withAlpha(45), shape: BoxShape.circle),
                        child: Icon(n.icon, color: n.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5))),
                            const Text('now', style: TextStyle(color: kMuted, fontSize: 11.5)),
                          ]),
                          const SizedBox(height: 2),
                          Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 13, height: 1.3)),
                        ]),
                      ),
                      // No tooltip here: the banner layer sits above the Navigator, so there is no Overlay
                      // ancestor and a Tooltip would throw.
                      Semantics(
                        button: true,
                        label: 'Dismiss',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: () => dismissNotice(n.id),
                          icon: const Icon(Icons.close, color: kMuted),
                        ),
                      ),
                    ]),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(seconds: kNoticeSeconds),
                    builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 3, color: n.color, backgroundColor: Colors.transparent),
                  ),
                ]),
              )),
            ),
          ),
        ),
      );
}

extension NoticeDemos on AppState {
  void simulateFriendRequest() {
    for (final p in kPlayers) {
      if (!friends.contains(p.tag) && !incomingFriendReqs.contains(p) && !invited.contains(p.tag) && !blocked.contains(p.tag)) {
        incomingFriendReqs.add(p);
        touch();
        pushNotice('Friend requests', Icons.person_add_alt, 'New friend request', '${p.tag} wants to join your squad.', tab: 2);
        return;
      }
    }
  }

  void simulateGroupRequest() {
    final gs = manageableGroups;
    if (gs.isEmpty) return;
    final g = gs.first;
    for (final p in kPlayers) {
      if (!g.requests.contains(p) && !friends.contains(p.tag) && !incomingFriendReqs.contains(p)) {
        g.requests.add(p);
        touch();
        pushNotice('Group activity', Icons.groups, 'New join request', '${p.tag} wants to join ${g.name}.', color: Colors.amber, tab: 2);
        return;
      }
    }
  }

  void simulateNews() {
    final u = me;
    if (u == null) return;
    for (final n in kNews) {
      if (n.games.any(u.followed.contains)) {
        pushNotice('News & releases', Icons.newspaper, 'News about ${n.games.firstWhere(u.followed.contains)}', n.title, color: Colors.lightBlueAccent, tab: 5);
        return;
      }
    }
  }
}


// ───────────────────────── Ranks, play style & extra profile info ─────────────────────────
// Rank ladders per game. Names are written from memory, so check them against each game before launch.
const _kLadderValorant = ['Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Ascendant', 'Immortal', 'Radiant'];
const _kLadderCod = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Crimson', 'Iridescent', 'Top 250'];
const _kLadderFc = [
  'Division 10', 'Division 9', 'Division 8', 'Division 7', 'Division 6', 'Division 5', 'Division 4', 'Division 3', 'Division 2', 'Division 1', 'Elite Division',
];
const _kLadderGeneric = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master', 'Grandmaster'];

const kRankLadders = <String, List<String>>{
  'Marvel Rivals': ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Grandmaster', 'Celestial', 'Eternity', 'One Above All'],
  'Valorant': _kLadderValorant,
  'Apex Legends': ['Rookie', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master', 'Apex Predator'],
  'League of Legends': ['Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Emerald', 'Diamond', 'Master', 'Grandmaster', 'Challenger'],
  'Rocket League': ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Champion', 'Grand Champion', 'Supersonic Legend'],
  'Counter-Strike 2': ['Silver', 'Gold Nova', 'Master Guardian', 'Legendary Eagle', 'Supreme', 'Global Elite'],
  'Overwatch 2': ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master', 'Grandmaster', 'Champion'],
  'Fortnite': ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Elite', 'Champion', 'Unreal'],
  'Call of Duty: Warzone': _kLadderCod,
  'Call of Duty: Modern Warfare 4': _kLadderCod,
  'EA Sports FC 27': _kLadderFc,
  'EA Sports FC 26': _kLadderFc,
  'Halo Infinite': ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Onyx'],
  'Street Fighter 6': ['Rookie', 'Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master', 'Legend'],
  'Tekken 8': ['Beginner', 'Fighter', 'Warrior', 'Dragon', 'God of Destruction', 'Tekken King'],
  'Destiny 2': _kLadderGeneric,
  'Forza Horizon 5': _kLadderGeneric,
  'F1 24': _kLadderGeneric,
};

const kUnranked = 'Unranked';
const kPlayStyles = ['Casual', 'Competitive', 'Grinder', 'Social / chill'];
const kLookingFor = ['Duo partner', 'Regular squad', 'Clan / team', 'Just for tonight'];
const kLangs = ['English', 'Spanish', 'French', 'German', 'Portuguese', 'Japanese', 'Korean', 'Arabic'];
const kRolePicks = ['Flexible', 'Tank', 'Support / healer', 'Damage', 'Strategist', 'Fragger', 'Sniper', 'Leader / IGL', 'Striker', 'Midfielder', 'Defender', 'Goalkeeper'];
const kThemes = [Color(0xFF0070CC), Color(0xFF8E44AD), Color(0xFFE67E22), Color(0xFF16A085), Color(0xFFC0392B), Color(0xFFD4AC0D)];
const _kAsk = [
  'My best clutch moment',
  'Why I main my favourite character',
  'The meta right now',
  'Tips for climbing ranked',
  'My setup and settings',
  'Co-op game recommendations',
];
const kFavPicks = <String, List<String>>{
  'Marvel Rivals': ['Spider-Man', 'Luna Snow', 'Doctor Strange', 'Iron Man', 'Storm'],
  'Valorant': ['Jett', 'Sage', 'Omen', 'Reyna', 'Sova'],
  'Apex Legends': ['Wraith', 'Bloodhound', 'Lifeline', 'Octane', 'Pathfinder'],
  'Overwatch 2': ['Tracer', 'Mercy', 'Reinhardt', 'Genji', 'Ana'],
  'League of Legends': ['Ahri', 'Lee Sin', 'Thresh', 'Jinx', 'Yasuo'],
  'Rocket League': ['Octane', 'Fennec', 'Dominus', 'Breakout'],
  'Street Fighter 6': ['Ryu', 'Chun-Li', 'Luke', 'Kimberly', 'Ken'],
  'Tekken 8': ['Jin', 'Kazuya', 'Paul', 'Nina', 'King'],
};

List<String>? ladderOf(String game) => kRankLadders[game];
int _hash(String s) => s.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);

/// Demo rank for a mock player (null when the game has no ranked ladder).
String? playerRank(Player p, String game) {
  final l = ladderOf(game);
  if (l == null) return null;
  final h = _hash('${p.tag}|$game');
  if (h % 9 == 0) return kUnranked;
  final tier = kRanks.indexOf(p.rank);
  final base = (l.length * (tier + 1) / 6).floor();
  final idx = (base + h % 3 - 1).clamp(0, l.length - 1).toInt();
  return l[idx];
}

int rankIndex(String game, String? r) {
  final l = ladderOf(game);
  if (l == null || r == null) return -1;
  return l.indexOf(r);
}

Color rankColor(String game, String? r) {
  final l = ladderOf(game);
  final i = rankIndex(game, r);
  if (l == null || i < 0) return kMuted;
  const cols = [Color(0xFFB07A4A), Color(0xFFB0B7C3), Color(0xFFFFC53D), Color(0xFF3DDAD7), Color(0xFFB06CFF), Color(0xFFFF7A45)];
  final f = l.length <= 1 ? 0.0 : i / (l.length - 1);
  return cols[(f * 5).round()];
}

List<String> favPicks(String game, String seed) {
  final l = kFavPicks[game];
  if (l == null) return const [];
  final h = _hash('$seed|$game');
  return [for (var i = 0; i < 3; i++) l[(h + i * 2) % l.length]].toSet().toList();
}

class RankBadge extends StatelessWidget {
  final String game;
  final String? rank;
  final bool linked, showGame;
  const RankBadge(this.game, this.rank, {super.key, this.linked = false, this.showGame = false});
  @override
  Widget build(BuildContext context) {
    final r = rank;
    if (r == null) return const SizedBox.shrink();
    final c = rankColor(game, r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withAlpha(36), border: Border.all(color: c.withAlpha(120)), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.military_tech, size: 14, color: c),
        const SizedBox(width: 4),
        Flexible(child: Text(showGame ? '$game · $r' : r, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        if (linked) ...[const SizedBox(width: 4), Icon(Icons.verified, size: 12, color: c)],
      ]),
    );
  }
}

/// Extra (demo) profile details for the mock players, derived from the gamertag so they stay stable.
extension PlayerExtras on Player {
  int get _h => _hash(tag);
  String get playStyle => kPlayStyles[_h % kPlayStyles.length];
  String get lookingFor => kLookingFor[(_h ~/ 3) % kLookingFor.length];
  bool get hasMic => _h % 5 != 0;
  List<String> get languages => ['English', if (_h % 3 == 0) kLangs[1 + _h % 7]];
  int get reliability => 72 + _h % 28;
  int get weeklyHours => 4 + _h % 28;
  int get utcOffset {
    switch (region) {
      case 'North America':
        return -5;
      case 'South America':
        return -3;
      case 'Asia':
        return 8;
      case 'Oceania':
        return 10;
      case 'Africa':
        return 2;
      case 'Middle East':
        return 3;
      default:
        return 0;
    }
  }

  String get localTime => fmtTime(DateTime.now().toUtc().add(Duration(hours: utcOffset)));
  String get tzLabel => 'UTC${utcOffset >= 0 ? '+' : ''}$utcOffset';
  String get lastActive => status == 'online' ? 'Online now' : (status == 'away' ? 'Active 20 min ago' : 'Active ${1 + _h % 20} hours ago');
  DateTime get memberSince => DateTime(2023 + _h % 3, 1 + _h % 12, 1 + _h % 27);
  bool get verified => _h % 3 != 1;
  List<String> get otherPlatforms => [for (final x in kPlatforms) if (x != platform && (_h + x.length) % 4 == 0) x];
  String get pronouns => const ['he/him', 'she/her', 'they/them', '', ''][_h % 5];
  String get askMe => _kAsk[_h % _kAsk.length];
  String get discord => tag.toLowerCase();
  String? get twitch => _h % 2 == 0 ? 'twitch.tv/${tag.toLowerCase()}' : null;
  Color get themeColor => kThemes[_h % kThemes.length];
}

bool canSeeSocial(Player p) => p._h % 4 == 0 ? S.friends.contains(p.tag) : canSee(p, 'Social links');

List<Player> mutualSquad(Player p) {
  final out = <Player>{};
  for (final g in S.groups) {
    if (g.memberOf(p) == null) continue;
    for (final m in g.members) {
      final w = m.who;
      if (w is Player && w != p && S.friends.contains(w.tag)) out.add(w);
    }
  }
  return out.toList();
}

Widget gameBanner(String game, {double h = 120, String label = 'MAIN GAME', Widget? corner}) => SizedBox(
      height: h,
      child: Stack(fit: StackFit.expand, children: [
        CoverImage(game),
        DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(200)])),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 10,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.9)),
            Text(game, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
        ),
        if (corner != null) Positioned(top: 10, right: 10, child: corner),
      ]),
    );

List<Widget> playerExtraSecs(BuildContext context, Player p) {
  final games = canSee(p, 'Games') ? p.games : <String>[];
  final rankedGames = [for (final g in games) if (ladderOf(g) != null) g];
  final main = games.isEmpty ? null : games.first;
  final picks = main == null ? <String>[] : favPicks(main, p.tag);
  final mutual = mutualSquad(p);
  final shared = [for (final g in S.groupsOf(p)) if (gIsMember(g)) g];
  return [
    Sec(
      'Ranks',
      !canSee(p, 'Rank')
          ? lockedRow('Ranks are not public')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (rankedGames.isEmpty) const Text('No ranked games to show.', style: TextStyle(color: kMuted)),
              for (final g in rankedGames)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    gameThumb(g, w: 40, h: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    RankBadge(g, playerRank(p, g), linked: p.verified),
                  ]),
                ),
              const SizedBox(height: 6),
              Text(p.verified ? 'Verified through a linked account (demo data).' : 'Self-reported rank.', style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
    ),
    Sec(
      'Play style & comms',
      !canSee(p, 'Play style & comms')
          ? lockedRow('Play style is not public')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                infoChip(p.playStyle, icon: Icons.flag_outlined),
                infoChip('Role: ${p.role}', icon: Icons.shield_outlined),
                infoChip('Looking for: ${p.lookingFor}', icon: Icons.search),
                infoChip(p.hasMic ? 'Has a mic' : 'No mic', icon: p.hasMic ? Icons.mic : Icons.mic_off),
                infoChip(p.languages.join(', '), icon: Icons.translate),
              ]),
              if (picks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Favourite picks in $main', style: const TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final x in picks) infoChip(x, icon: Icons.star_outline)]),
              ],
            ]),
    ),
    Sec(
      'Activity & reliability',
      !canSee(p, 'Activity & reliability')
          ? lockedRow('Activity is not public')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Reliability: ${p.reliability}%', style: const TextStyle(fontWeight: FontWeight.bold))),
                if (p.verified) const Icon(Icons.verified, size: 18, color: kAccent),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: p.reliability / 100, minHeight: 6, backgroundColor: kField, color: p.reliability >= 85 ? kOnline : Colors.amber),
              ),
              const SizedBox(height: 4),
              const Text('How often they show up to sessions they agreed to.', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 12),
              detailRow(Icons.circle, p.lastActive),
              detailRow(Icons.schedule, 'Their time: ${p.localTime} (${p.tzLabel})'),
              detailRow(Icons.timelapse, 'Plays about ${p.weeklyHours} hours a week · ${p.avail}'),
              detailRow(Icons.cake_outlined, 'Member since ${fmtDate(p.memberSince)}'),
            ]),
    ),
    Sec(
      'Connections',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Also plays on', style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          infoChip(p.platform, icon: Icons.sports_esports),
          for (final x in p.otherPlatforms) infoChip(x, icon: Icons.devices_other),
        ]),
        const SizedBox(height: 12),
        Text('Squad mates you both know', style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 6),
        if (mutual.isEmpty)
          const Text('None yet.', style: TextStyle(color: kMuted))
        else
          Wrap(spacing: 10, runSpacing: 8, children: [
            for (final m in mutual)
              InkWell(
                onTap: () => openPlayer(context, m),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Avatar(m.avatar, radius: 12), const SizedBox(width: 6), Text(m.tag)]),
              ),
          ]),
        if (shared.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Groups you are both in: ${shared.map((g) => g.name).join(', ')}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
        ],
      ]),
    ),
    Sec(
      'Social links',
      !canSeeSocial(p)
          ? lockedRow('Social links are shared with squad mates only')
          : Wrap(spacing: 8, runSpacing: 8, children: [
              infoChip('Discord: ${p.discord}', icon: Icons.forum_outlined),
              if (p.twitch != null) infoChip(p.twitch!, icon: Icons.live_tv),
            ]),
    ),
    Sec('Ask me about', Text('“${p.askMe}”', style: const TextStyle(fontStyle: FontStyle.italic))),
  ];
}

/// "My ranks & roles": one tile per game on your own profile.
class RankEditor extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const RankEditor({super.key, required this.p, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    if (p.games.isEmpty) return const Text('Add a game under "My games" first.', style: TextStyle(color: kMuted));
    final linked = p.linked.values.any((v) => v);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        linked
            ? 'Ranks are self-reported for now. Once game APIs are connected, ranks from your linked account will show a verified tick.'
            : 'Choose your rank in each game. Link a gaming account to be able to verify it later.',
        style: const TextStyle(color: kMuted, fontSize: 12.5),
      ),
      const SizedBox(height: 12),
      for (final g in p.games)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              gameThumb(g, w: 40, h: 24),
              const SizedBox(width: 10),
              Expanded(child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (ladderOf(g) != null) RankBadge(g, p.gameRank[g] ?? kUnranked),
            ]),
            const SizedBox(height: 10),
            if (ladderOf(g) != null)
              PickField(
                label: 'Rank in $g',
                value: p.gameRank[g] ?? kUnranked,
                options: [kUnranked, ...ladderOf(g)!],
                onChanged: (v) {
                  p.gameRank[g] = v;
                  onChanged();
                },
              )
            else
              const Text('This game has no ranked ladder in SquadUp.', style: TextStyle(color: kMuted, fontSize: 12.5)),
            const SizedBox(height: 10),
            PickField(
              label: 'Preferred role in $g',
              value: p.gameRole[g] ?? 'Flexible',
              options: kRolePicks,
              onChanged: (v) {
                p.gameRole[g] = v;
                onChanged();
              },
            ),
            const SizedBox(height: 10),
            outLabel(
              'Favourite heroes, characters or loadouts',
              TextFormField(
                key: ValueKey('picks$g'),
                initialValue: p.gamePicks[g] ?? '',
                maxLength: 60,
                onChanged: (v) => p.gamePicks[g] = v,
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// "Play style & contact": comms, languages, links, pronouns and profile colour.
class StyleEditor extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const StyleEditor({super.key, required this.p, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I have a mic'),
          value: p.hasMic,
          onChanged: (v) {
            p.hasMic = v;
            onChanged();
          },
        ),
        outLabel('Languages (separate with commas)', TextFormField(initialValue: p.languages, onChanged: (v) => p.languages = v)),
        const SizedBox(height: 12),
        outLabel('Pronouns (optional)', TextFormField(initialValue: p.pronouns, maxLength: 20, onChanged: (v) => p.pronouns = v)),
        outLabel('Ask me about…', TextFormField(initialValue: p.askMe, maxLength: 60, onChanged: (v) => p.askMe = v)),
        const SizedBox(height: 4),
        outLabel('Discord username', TextFormField(initialValue: p.discord, onChanged: (v) => p.discord = v)),
        const SizedBox(height: 12),
        outLabel('Twitch / YouTube link', TextFormField(initialValue: p.twitch, onChanged: (v) => p.twitch = v)),
        const SizedBox(height: 14),
        const Text('Profile colour', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, children: [
          for (var i = 0; i < kThemes.length; i++)
            GestureDetector(
              onTap: () {
                p.theme = i;
                onChanged();
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: kThemes[i],
                child: p.theme == i ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
            ),
        ]),
        const SizedBox(height: 10),
        const Text('Reliability builds up as you turn up to sessions. Who can see each of these is set under Privacy.', style: TextStyle(color: kMuted, fontSize: 12.5)),
      ]);
}

// ── Notifications for everything ──
int _demoNext = 0;
final _unlockedAch = <String>{};
bool _achReady = false;

/// Shows a banner whenever a new achievement is unlocked (called after any profile/state update).
void checkAchievements() {
  final u = S.me;
  if (u == null) return;
  final list = achievements(u);
  if (!_achReady) {
    _unlockedAch
      ..clear()
      ..addAll([for (final a in list) if (a.$4) a.$2]);
    _achReady = true;
    return;
  }
  for (final a in list) {
    if (a.$4 && _unlockedAch.add(a.$2)) {
      pushNotice('Achievements & ranks', Icons.emoji_events, 'Achievement unlocked', '${a.$2}: ${a.$3}', color: Colors.amber, tab: 2);
    }
  }
}

extension MoreNoticeDemos on AppState {
  void simulateCommend() {
    final u = me;
    if (u == null) return;
    final p = kPlayers.firstWhere((x) => !blocked.contains(x.tag), orElse: () => kPlayers.first);
    pushNotice('Commendations', Icons.thumb_up_alt, 'New commendation', '${p.tag} commended you: ${kCommends[p.tag.length % kCommends.length]}', color: Colors.pinkAccent, tab: 2);
  }

  void simulateRankUp() {
    final u = me;
    if (u == null) return;
    for (final g in u.games) {
      final l = ladderOf(g);
      if (l == null) continue;
      final i = l.indexOf(u.gameRank[g] ?? kUnranked);
      if (i + 1 >= l.length) continue;
      u.gameRank[g] = l[i + 1];
      touch();
      pushNotice('Achievements & ranks', Icons.military_tech, 'Rank up!', 'You reached ${l[i + 1]} in $g.', color: rankColor(g, l[i + 1]), tab: 2);
      return;
    }
    pushNotice('Achievements & ranks', Icons.military_tech, 'Rank updates', 'Add a ranked game and set your rank to see rank-up alerts.', tab: 2);
  }

  void simulateEventReminder() {
    final now = DateTime.now();
    final up = events.where((e) => e.when.isAfter(now)).toList()..sort((a, b) => a.when.compareTo(b.when));
    if (up.isEmpty) return;
    final e = up.first;
    pushNotice('Event reminders', Icons.event, 'Event reminder', '${e.title} · ${e.game} · ${fmtWhen(e.when)}', color: Colors.orangeAccent, tab: 2);
  }

  void simulateJoinApproved() {
    final u = me;
    if (u == null) return;
    for (final g in groups) {
      if (g.requests.any((r) => identical(r, u))) {
        approve(g, u, true);
        pushNotice('Group activity', Icons.group_add, 'Join request approved', 'You are now a member of ${g.name}.', color: kOnline, tab: 4);
        return;
      }
    }
  }

  void simulateLfgReply() {
    final u = me;
    if (u == null) return;
    for (final l in lfg) {
      if (identical(l.who, u)) {
        final p = kPlayers.firstWhere((x) => x.games.contains(l.game), orElse: () => kPlayers.first);
        pushNotice('LFG & matches', Icons.sports_esports, '${p.tag} replied to your post', 'Interested in your ${l.game} session.', color: Colors.tealAccent, tab: 2);
        return;
      }
    }
    final p = kPlayers.first;
    pushNotice('LFG & matches', Icons.sports_esports, 'New match for you', '${p.tag} is a ${matchScore(u, p)}% match and is online now.', color: Colors.tealAccent, tab: 1);
  }

  /// "Send a test notification": each tap shows the next type of notification.
  void demoNext() {
    switch (_demoNext++ % 9) {
      case 0:
        pushNotice('Messages', Icons.chat_bubble, 'NovaStrike', 'Yo, are you around tonight? 🎮', tab: 3);
      case 1:
        simulateFriendRequest();
      case 2:
        simulateGroupRequest();
      case 3:
        simulateCommend();
      case 4:
        simulateRankUp();
      case 5:
        simulateEventReminder();
      case 6:
        simulateLfgReply();
      case 7:
        pushNotice('Safety & support', Icons.support_agent, 'Report received', 'Thanks, our team is reviewing it.', color: Colors.lightGreenAccent, tab: 6);
      default:
        simulateNews();
    }
  }
}

void resetAchievementWatch() {
  _achReady = false;
  _unlockedAch.clear();
}

// ───────────────────────── Gamer types, teammate wishes & hidden player types ─────────────────────────
const kGamerTypes = ['Competitive', 'Casual', 'Social / friends', 'Story & co-op', 'Streamer / creator', 'Team leader', 'Beginner', 'Returning player'];
const _wMic = 'Teammates with a mic';
const _wRanked = 'Ranked / competitive';
const _wCasual = 'Casual, no pressure';
const _wFriends = 'Friends long term';
const _wDuo = 'A duo partner';
const _wSquad = 'A full squad or clan';
const _wSkill = 'Similar skill level';
const _wAge = 'Similar age group';
const _wLang = 'Same language';
const _wChill = 'Chill, no toxicity';
const _wTimes = 'Plays at my times';
const kWants = [_wMic, _wRanked, _wCasual, _wFriends, _wDuo, _wSquad, _wSkill, _wAge, _wLang, _wChill, _wTimes];
const _aNoMic = 'Players without a mic';
const _aMinor = 'Players under 18';
const _aLang = "Players who don't share my language";
const _aLower = 'Much lower skill than me';
const _aHigher = 'Much higher skill than me';
const _aTimes = 'Players who play at other times';
const _aCasual = 'Casual-only players';
const _aComp = 'Competitive / ranked grinders';
const kAvoids = [_aNoMic, _aMinor, _aLang, _aLower, _aHigher, _aTimes, _aCasual, _aComp];
const _kWantShort = {
  _wMic: 'Has a mic',
  _wRanked: 'Competitive',
  _wCasual: 'Casual',
  _wFriends: 'Social',
  _wDuo: 'Wants a duo',
  _wSquad: 'Wants a squad',
  _wSkill: 'Similar skill',
  _wAge: 'Similar age',
  _wLang: 'Same language',
  _wChill: 'Reliable and chill',
  _wTimes: 'Same play times',
};

extension PlayerTags on Player {
  Set<String> get gamerTypes {
    final h = _hash('types$tag');
    final s = <String>{};
    switch (playStyle) {
      case 'Competitive':
      case 'Grinder':
        s.add(kGamerTypes[0]);
      case 'Casual':
        s.add(kGamerTypes[1]);
      default:
        s.add(kGamerTypes[2]);
    }
    if (role == 'IGL' || role == 'Strategist' || role == 'Leader / IGL') s.add(kGamerTypes[5]);
    if (rank == 'Beginner') s.add(kGamerTypes[6]);
    if (h % 7 == 0) s.add(kGamerTypes[4]);
    if (h % 6 == 0) s.add(kGamerTypes[3]);
    if (h % 11 == 0) s.add(kGamerTypes[7]);
    return s;
  }

  Set<String> get wants {
    final h = _hash('wants$tag');
    return {kWants[h % kWants.length], kWants[(h ~/ 3 + 2) % kWants.length], if (hasMic && h % 2 == 0) _wMic};
  }
}

bool _langOverlap(Profile me, Player p) {
  final mine = me.languages.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
  if (mine.isEmpty) return true;
  return p.languages.any((l) => mine.contains(l.toLowerCase()));
}

/// Average rank gap (their rank minus yours, 0-1 of the ladder) over shared ranked games; null when unknown.
double? _skillGap(Profile me, Player p) {
  var sum = 0.0;
  var n = 0;
  for (final g in p.games) {
    final l = ladderOf(g);
    final mine = me.gameRank[g];
    final theirs = playerRank(p, g);
    if (!me.games.contains(g) || l == null || l.length < 2 || mine == null || mine == kUnranked || theirs == null || theirs == kUnranked) continue;
    sum += (l.indexOf(theirs) - l.indexOf(mine)) / (l.length - 1);
    n++;
  }
  return n == 0 ? null : sum / n;
}

bool _sameTimes(Profile me, Player p) => me.avail == p.avail || me.avail == 'Anytime' || p.avail == 'Anytime';

bool wantMet(Profile me, Player p, String w) {
  switch (w) {
    case _wMic:
      return p.hasMic;
    case _wRanked:
      return p.gamerTypes.contains(kGamerTypes[0]);
    case _wCasual:
      return p.gamerTypes.contains(kGamerTypes[1]);
    case _wFriends:
      return p.gamerTypes.contains(kGamerTypes[2]);
    case _wDuo:
      return p.lookingFor == 'Duo partner';
    case _wSquad:
      return p.lookingFor == 'Regular squad' || p.lookingFor == 'Clan / team';
    case _wSkill:
      {
        final g = _skillGap(me, p);
        return g != null && g.abs() <= 0.25;
      }
    case _wAge:
      return me.dob != null && (ageOf(me.dob!) - p.age).abs() <= 5;
    case _wLang:
      return _langOverlap(me, p);
    case _wChill:
      return p.reliability >= 85;
    case _wTimes:
      return _sameTimes(me, p);
    default:
      return false;
  }
}

bool avoidHit(Profile me, Player p, String a) {
  switch (a) {
    case _aNoMic:
      return !p.hasMic;
    case _aMinor:
      return p.age < 18;
    case _aLang:
      return !_langOverlap(me, p);
    case _aLower:
      {
        final g = _skillGap(me, p);
        return g != null && g < -0.3;
      }
    case _aHigher:
      {
        final g = _skillGap(me, p);
        return g != null && g > 0.3;
      }
    case _aTimes:
      return !_sameTimes(me, p);
    case _aCasual:
      return p.gamerTypes.contains(kGamerTypes[1]) && !p.gamerTypes.contains(kGamerTypes[0]);
    case _aComp:
      return p.gamerTypes.contains(kGamerTypes[0]);
    default:
      return false;
  }
}

/// True when the player is hidden by the types of players you chose to hide.
bool hiddenByPrefs(Profile me, Player p) => !me.showFiltered && me.avoids.any((a) => avoidHit(me, p, a));
int hiddenCount(Profile me) => me.avoids.isEmpty ? 0 : kPlayers.where((p) => !S.blocked.contains(p.tag) && me.avoids.any((a) => avoidHit(me, p, a))).length;

/// 0-1: how well the player fits what you said you want. Neutral (0.5) when you have not chosen anything.
double tagScore(Profile me, Player p) {
  var sum = 0.0;
  var n = 0;
  if (me.wants.isNotEmpty) {
    sum += me.wants.where((w) => wantMet(me, p, w)).length / me.wants.length;
    n++;
  }
  if (me.gamerTypes.isNotEmpty) {
    sum += me.gamerTypes.intersection(p.gamerTypes).isEmpty ? 0.0 : 1.0;
    n++;
  }
  return n == 0 ? 0.5 : sum / n;
}

List<String> whyMatch(Profile me, Player p) {
  final r = <String>[
    for (final w in me.wants)
      if (wantMet(me, p, w)) _kWantShort[w] ?? w,
    for (final t in me.gamerTypes.intersection(p.gamerTypes)) 'Both ${t.split(RegExp(r'[ ,/]')).first.toLowerCase()}',
  ];
  return r.take(4).toList();
}

class TagPicker extends StatelessWidget {
  final String title, hint;
  final List<String> options;
  final Set<String> selected;
  final VoidCallback onChanged;
  const TagPicker({super.key, required this.title, required this.hint, required this.options, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(hint, style: const TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in options)
            FilterChip(
              label: Text(o),
              selected: selected.contains(o),
              onSelected: (v) {
                if (v) {
                  selected.add(o);
                } else {
                  selected.remove(o);
                }
                onChanged();
              },
            ),
        ]),
      ]);
}

/// Gamer type, what you want in teammates, and the types of players you want hidden.
class PrefsEditor extends StatelessWidget {
  final Profile p;
  final VoidCallback onChanged;
  const PrefsEditor({super.key, required this.p, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TagPicker(title: 'What type of gamer are you?', hint: 'Pick all that fit.', options: kGamerTypes, selected: p.gamerTypes, onChanged: onChanged),
        const SizedBox(height: 18),
        TagPicker(title: 'What teammates are you looking for?', hint: 'Players who fit these get a higher match score.', options: kWants, selected: p.wants, onChanged: onChanged),
        const SizedBox(height: 18),
        TagPicker(
          title: 'Hide these types of players',
          hint: 'They will not appear in Find Team or your suggestions. You can still turn them back on.',
          options: kAvoids,
          selected: p.avoids,
          onChanged: onChanged,
        ),
        if (p.avoids.isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show hidden players anyway'),
            subtitle: Text('${hiddenCount(p)} player${hiddenCount(p) == 1 ? '' : 's'} currently hidden'),
            value: p.showFiltered,
            onChanged: (v) {
              p.showFiltered = v;
              onChanged();
            },
          ),
      ]);
}

List<Widget> playerTagSecs(Player p) {
  final me = S.me;
  if (!canSee(p, 'Play style & comms')) return [Sec('Gamer type & teammates', lockedRow('Not public'))];
  final why = me == null ? <String>[] : whyMatch(me, p);
  return [
    if (why.isNotEmpty)
      Sec('Why you match', Wrap(spacing: 8, runSpacing: 8, children: [for (final w in why) infoChip(w, icon: Icons.check_circle_outline, color: kOnline)])),
    Sec(
      'Gamer type',
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in p.gamerTypes) infoChip(t, icon: me != null && me.gamerTypes.contains(t) ? Icons.check : Icons.sports_esports_outlined, color: me != null && me.gamerTypes.contains(t) ? kOnline : null),
      ]),
    ),
    Sec(
      'Looking for in teammates',
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final w in p.wants) infoChip(w, icon: me != null && me.wants.contains(w) ? Icons.check : Icons.person_search_outlined, color: me != null && me.wants.contains(w) ? kOnline : null),
      ]),
    ),
  ];
}

// ───────────────────────── Member labels, communities & member limits ─────────────────────────
class GLabel {
  final String id;
  String name;
  int color;
  GLabel(this.id, this.name, this.color);
  Color get c => Color(color);
}

class LabelReq {
  final Object who;
  final String labelId;
  LabelReq(this.who, this.labelId);
}

class GChannel {
  String name;
  final List<Post> posts;
  GChannel(this.name, this.posts);
}

const kLabelColors = [0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF43A047, 0xFF26A69A, 0xFF1E88E5, 0xFF8E24AA, 0xFFEC407A, 0xFF78909C];

const kLabelTemplates = <String, List<(String, int)>>{
  'Start blank': [],
  'Pro Clubs positions': [
    ('GK', 0xFFFDD835), ('CB', 0xFF1E88E5), ('LB', 0xFF42A5F5), ('RB', 0xFF42A5F5), ('CDM', 0xFF26A69A),
    ('CM', 0xFF43A047), ('CAM', 0xFF7CB342), ('LW', 0xFF8E24AA), ('RW', 0xFF8E24AA), ('ST', 0xFFE53935),
  ],
  'GTA roleplay roles': [
    ('Police', 0xFF1E88E5), ('EMS / Medic', 0xFFE53935), ('Mechanic', 0xFFFB8C00), ('Taxi driver', 0xFFFDD835),
    ('Business owner', 0xFF43A047), ('Gang member', 0xFF8E24AA), ('Civilian', 0xFF78909C),
  ],
  'Esports team roles': [('IGL', 0xFFE53935), ('Entry', 0xFFFB8C00), ('Support', 0xFF43A047), ('Sniper', 0xFF1E88E5), ('Lurker', 0xFF8E24AA), ('Coach', 0xFF78909C)],
  'Raid roles': [('Tank', 0xFF1E88E5), ('Healer', 0xFF43A047), ('DPS', 0xFFE53935), ('Support', 0xFFFB8C00)],
};

GLabel? labelOf(Group g, String id) {
  for (final l in g.labels) {
    if (l.id == id) return l;
  }
  return null;
}

void applyTemplate(Group g, String name) {
  for (final (n, c) in kLabelTemplates[name] ?? const <(String, int)>[]) {
    if (g.labels.any((l) => l.name == n)) continue;
    g.labels.add(GLabel('l${DateTime.now().microsecondsSinceEpoch}${g.labels.length}', n, c));
  }
}

bool gLabelsVisible(Group g) => gIsMember(g) || g.canView('Labels');

Widget labelChip(GLabel l) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: l.c.withAlpha(46), border: Border.all(color: l.c.withAlpha(150)), borderRadius: BorderRadius.circular(8)),
      child: Text(l.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );

Widget labelTags(Group g, GMember m) => Wrap(spacing: 4, runSpacing: 4, children: [
      for (final id in m.labels)
        if (labelOf(g, id) != null) labelChip(labelOf(g, id)!),
    ]);

Future<void> editLabel(BuildContext context, Group g, GLabel? l) async {
  final name = TextEditingController(text: l?.name ?? '');
  var color = l?.color ?? kLabelColors.first;
  await showDialog<void>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        backgroundColor: kCard,
        title: Text(l == null ? 'Add label' : 'Edit label'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            outLabel('Label name', TextField(controller: name, autofocus: true, maxLength: 24)),
            const SizedBox(height: 8),
            const Text('Colour', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final c in kLabelColors)
                GestureDetector(
                  onTap: () => set(() => color = c),
                  child: CircleAvatar(radius: 15, backgroundColor: Color(c), child: color == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
                ),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final t = name.text.trim();
              if (t.isEmpty) {
                toast('Give the label a name');
                return;
              }
              if (l == null) {
                g.labels.add(GLabel('l${DateTime.now().microsecondsSinceEpoch}', t, color));
              } else {
                l.name = t;
                l.color = color;
              }
              S.update();
              Navigator.pop(d);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> addTemplateSheet(BuildContext context, Group g) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Add labels from a template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          for (final e in kLabelTemplates.entries)
            if (e.value.isNotEmpty)
              ListTile(
                title: Text(e.key),
                subtitle: Text(e.value.map((x) => x.$1).join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  applyTemplate(g, e.key);
                  S.update();
                  Navigator.pop(c);
                  toast('Labels added');
                },
              ),
        ]),
      ),
    );

Future<void> editLimitDialog(BuildContext context, Group g) async {
  final c = TextEditingController(text: g.maxMembers?.toString() ?? '');
  final least = g.members.length < 2 ? 2 : g.members.length;
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: kCard,
      title: const Text('Member limit'),
      content: outLabel('Maximum members (${g.members.length} now)', TextField(controller: c, keyboardType: TextInputType.number, autofocus: true)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            g.maxMembers = null;
            S.update();
            Navigator.pop(d);
          },
          child: const Text('No limit'),
        ),
        FilledButton(
          onPressed: () {
            final n = int.tryParse(c.text.trim());
            if (n == null || n < least) {
              toast('Enter a number of $least or more');
              return;
            }
            g.maxMembers = n;
            S.update();
            Navigator.pop(d);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> editRulesDialog(BuildContext context, Group g) async {
  final c = TextEditingController(text: g.rules);
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: kCard,
      title: const Text('Community rules'),
      content: SizedBox(width: 420, child: outLabel('Rules', TextField(controller: c, maxLines: 6, maxLength: 600, autofocus: true))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            g.rules = c.text.trim();
            S.update();
            Navigator.pop(d);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// Squad sheet: members listed by label, with empty slots flagged. Owners manage labels here.
class SquadSheetTab extends StatelessWidget {
  final Group g;
  const SquadSheetTab(this.g, {super.key});

  @override
  Widget build(BuildContext context) {
    final member = gIsMember(g);
    if (!member && !g.canView('Squad sheet')) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('The owner has hidden the squad sheet from non-members')));
    }
    final manage = gCanManage(g);
    final names = member || g.canView('Members');
    final me = S.me;
    final unlabelled = g.members.where((m) => m.labels.isEmpty).toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (manage)
            Sec(
              'Manage labels',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Labels show next to members. Use them for positions, roles or anything else. Assign them from the Members tab.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final l in g.labels)
                    InputChip(
                      avatar: CircleAvatar(backgroundColor: l.c, radius: 6),
                      label: Text(l.name),
                      onPressed: () => editLabel(context, g, l),
                      onDeleted: () {
                        for (final m in g.members) {
                          m.labels.remove(l.id);
                        }
                        g.labelReqs.removeWhere((r) => r.labelId == l.id);
                        g.labels.remove(l);
                        S.update();
                      },
                    ),
                  ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('Add label'), onPressed: () => editLabel(context, g, null)),
                ]),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => addTemplateSheet(context, g), icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Add from a template')),
              ]),
            ),
          if (manage && g.labelReqs.isNotEmpty)
            Sec(
              'Label requests (${g.labelReqs.length})',
              Column(children: [
                for (final r in List.of(g.labelReqs))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: whoAvatar(r.who, radius: 18),
                    title: Text('${whoName(r.who)} wants ${labelOf(g, r.labelId)?.name ?? 'a label'}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Decline', onPressed: () {
                        g.labelReqs.remove(r);
                        S.update();
                      }, icon: const Icon(Icons.close, color: Colors.redAccent)),
                      IconButton(tooltip: 'Approve', onPressed: () {
                        g.memberOf(r.who)?.labels.add(r.labelId);
                        g.labelReqs.remove(r);
                        S.update();
                      }, icon: const Icon(Icons.check, color: kAccent)),
                    ]),
                  ),
              ]),
            ),
          if (g.labels.isEmpty)
            Sec('Squad sheet', Text(manage ? 'No labels yet. Add some above or start from a template.' : 'The owner has not set up labels yet.', style: const TextStyle(color: kMuted))),
          for (final l in g.labels)
            Builder(builder: (context) {
              final holders = g.members.where((m) => m.labels.contains(l.id)).toList();
              final mineHas = me != null && g.memberOf(me)?.labels.contains(l.id) == true;
              final pending = me != null && g.labelReqs.any((r) => identical(r.who, me) && r.labelId == l.id);
              return Sec(
                l.name,
                holders.isEmpty
                    ? const Text('Nobody yet', style: TextStyle(color: Colors.amber))
                    : names
                        ? Wrap(spacing: 12, runSpacing: 8, children: [
                            for (final m in holders) Row(mainAxisSize: MainAxisSize.min, children: [whoAvatar(m.who, radius: 12), const SizedBox(width: 6), Text(m.name)]),
                          ])
                        : Text('${holders.length} player${holders.length == 1 ? '' : 's'}', style: const TextStyle(color: kMuted)),
                action: member && !mineHas && !gIsOwner(g)
                    ? (pending
                        ? const Padding(padding: EdgeInsets.all(8), child: Text('Requested', style: TextStyle(color: kMuted, fontSize: 12)))
                        : TextButton(
                            onPressed: () {
                              final req = LabelReq(me!, l.id);
                              g.labelReqs.add(req);
                              S.update();
                              toast('Request sent to the owner');
                              if (g.owner.who is Player) {
                                Timer(const Duration(seconds: 10), () {
                                  if (!g.labelReqs.remove(req)) return;
                                  g.memberOf(me)?.labels.add(l.id);
                                  S.update();
                                  pushNotice('Group activity', Icons.label_outline, 'Label approved', 'You are now ${l.name} in ${g.name}.', color: l.c, tab: 4);
                                });
                              }
                            },
                            child: const Text('Request this'),
                          ))
                    : null,
              );
            }),
          if (names && g.labels.isNotEmpty && unlabelled.isNotEmpty)
            Sec('No label yet (${unlabelled.length})', Wrap(spacing: 12, runSpacing: 8, children: [for (final m in unlabelled) Text(m.name, style: const TextStyle(color: kMuted))])),
        ]),
      ),
    );
  }
}

/// Community chat: several channels, plus the rules gate for new members.
class CommunityChatTab extends StatefulWidget {
  final Group g;
  const CommunityChatTab(this.g, {super.key});
  @override
  State<CommunityChatTab> createState() => _CommunityChatTabState();
}

class _CommunityChatTabState extends State<CommunityChatTab> {
  int ch = 0;

  Future<void> addChannel() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('New channel'),
        content: outLabel('Channel name', TextField(controller: c, autofocus: true, maxLength: 24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    widget.g.channels.add(GChannel(name, []));
    S.update();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    if (!gIsMember(g)) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('Join this community to read and send messages')));
    }
    if (g.rules.trim().isNotEmpty && g.rulesRequired && !gIsOwner(g) && !g.accepted.contains(S.me)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Sec(
              'Community rules',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.rules),
                const SizedBox(height: 14),
                const Text('Please accept the rules to join the chat.', style: TextStyle(color: kMuted)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    g.accepted.add(S.me!);
                    S.update();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('I accept the rules'),
                ),
              ]),
            ),
          ]),
        ),
      );
    }
    if (ch >= g.channels.length) ch = 0;
    final channel = g.channels[ch];
    return Column(children: [
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), children: [
          for (var i = 0; i < g.channels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text('# ${g.channels[i].name}'), selected: i == ch, onSelected: (_) => setState(() => ch = i)),
            ),
          if (gCanManage(g)) ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('New channel'), onPressed: addChannel),
        ]),
      ),
      Expanded(child: GroupChatTab(g, key: ValueKey('${g.id}-${channel.name}'), posts: channel.posts, hint: 'Message #${channel.name}')),
    ]);
  }
}

/// Community events: only the community's own events.
class CommunityEventsTab extends StatelessWidget {
  final Group g;
  const CommunityEventsTab(this.g, {super.key});
  @override
  Widget build(BuildContext context) {
    final member = gIsMember(g);
    if (!member && !g.canView('Events')) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('The owner has hidden events from non-members')));
    }
    final list = S.events.where((e) => identical(e.group, g)).toList()..sort((a, b) => a.when.compareTo(b.when));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (gCanManage(g))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: () => showEventDialog(context, group: g), icon: const Icon(Icons.add), label: const Text('Create community event'))),
            ),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No community events yet.', style: TextStyle(color: kMuted)))),
          for (final e in list)
            Sec(
              e.title,
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${e.game} · ${fmtWhen(e.when)}', style: const TextStyle(color: kMuted)),
                    Text('${e.going.length} going · hosted by ${whoName(e.host)}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  ]),
                ),
                if (member)
                  e.going.any((x) => identical(x, S.me))
                      ? FilledButton(onPressed: () => S.toggleRsvp(e), child: const Text('Going'))
                      : OutlinedButton(onPressed: () => S.toggleRsvp(e), child: const Text('RSVP')),
              ]),
            ),
        ]),
      ),
    );
  }
}

List<Group> _seedCommunities(Profile demo, List<Group> gs) {
  GMember own(int i) => GMember(kPlayers[i], role: 'owner', canAnnounce: true, canManage: true);
  GMember adm(int i) => GMember(kPlayers[i], role: 'admin', canAnnounce: true, canManage: true);
  GMember mem(int i) => GMember(kPlayers[i]);
  void labelUp(Group g) {
    for (var i = 0; i < g.members.length; i++) {
      if (g.labels.isEmpty) return;
      g.members[i].labels.add(g.labels[(i * 3 + 1) % g.labels.length].id);
    }
  }

  final cs = <Group>[
    Group('c1', 'Pro Clubs UK Community', 'The home for UK Pro Clubs players: league nights, scrims and a position-based squad sheet.', true,
        ['EA Sports FC 27', 'EA Sports FC 26'], 'PlayStation', 'Europe',
        [own(4), adm(8), for (final i in const [0, 1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]) mem(i)]),
    Group('c2', 'Los Santos Roleplay', 'A serious GTA roleplay community with jobs, factions and weekly storylines.', true,
        ['Grand Theft Auto V', 'Grand Theft Auto VI'], 'PlayStation', 'Any',
        [own(12), adm(9), for (final i in const [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]) mem(i)]),
    Group('c3', 'SquadUp Demo Community', 'The demo community: you own it, so you can try channels, rules, moderators and labels.', false,
        ['Apex Legends', 'Valorant'], 'Any', 'Any',
        [GMember(demo, role: 'owner', canAnnounce: true, canManage: true), adm(5), mem(13), mem(9), mem(2), mem(7), mem(11)]),
  ];
  for (final g in cs) {
    g.isCommunity = true;
    g.show.addAll({'Rules': true, 'Events': true});
    g.rules = '1. Be respectful to everyone.\n2. No cheating, boosting or account sharing.\n3. Keep each channel on topic.\n4. Follow staff instructions.';
    g.chat.add(Post(g.owner.who, 'Welcome to ${g.name}! Read the rules, then say hi 👋'));
    g.channels[1].posts.add(Post(g.owner.who, 'Post your game, platform and time here to find a match.'));
    g.news.add(Post(g.owner.who, 'Community rules are in the Overview tab.'));
  }
  applyTemplate(cs[0], 'Pro Clubs positions');
  applyTemplate(cs[1], 'GTA roleplay roles');
  applyTemplate(cs[2], 'Esports team roles');
  applyTemplate(gs[1], 'Pro Clubs positions');
  for (final g in [cs[0], cs[1], cs[2], gs[1]]) {
    labelUp(g);
  }
  cs[0].members[2].mod = true;
  cs[1].members[2].mod = true;
  cs[2].maxMembers = 50;
  gs[6].maxMembers = gs[6].members.length; // a full group, so you can see the "Full" state
  return cs;
}

// ───────────────────────── Home shell ─────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Timer? _ping;
  final _extra = <Timer>[];
  static const dests = [
    (Icons.sports_esports_outlined, Icons.sports_esports, 'Home'), // games list
    (Icons.search, Icons.search, 'Find Team'),
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats'),
    (Icons.groups_outlined, Icons.groups, 'Groups'),
    (Icons.newspaper_outlined, Icons.newspaper, 'News'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];
  // Phone bottom bar shows these; everything else lives under "More".
  static const barItems = [0, 1, 2, 3];

  void _onNav() => setState(() {});

  @override
  void initState() {
    super.initState();
    navIndex.value = 0;
    navIndex.addListener(_onNav);
    _ping = Timer(const Duration(seconds: 25), S.simulatePing);
    _extra
      ..add(Timer(const Duration(seconds: 50), S.simulateFriendRequest))
      ..add(Timer(const Duration(seconds: 75), S.simulateGroupRequest))
      ..add(Timer(const Duration(seconds: 100), S.simulateNews))
      ..add(Timer(const Duration(seconds: 125), S.simulateCommend))
      ..add(Timer(const Duration(seconds: 150), S.simulateEventReminder))
      ..add(Timer(const Duration(seconds: 175), S.simulateJoinApproved))
      ..add(Timer(const Duration(seconds: 200), S.simulateRankUp));
  }

  @override
  void dispose() {
    _ping?.cancel();
    for (final t in _extra) {
      t.cancel();
    }
    navIndex.removeListener(_onNav);
    super.dispose();
  }

  Widget _icon(int idx, bool selected) {
    final d = dests[idx];
    Widget ic = Icon(selected ? d.$2 : d.$1);
    if (idx == 3 && S.totalUnread > 0) {
      ic = Badge(label: Text(S.totalUnread > 99 ? '99+' : '${S.totalUnread}'), child: ic);
    }
    return Pressable(scale: 0.9, child: selected ? NavPop(ic) : ic);
  }

  void _more() => showModalBottomSheet(
        context: context,
        backgroundColor: kCard,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final idx in [4, 5, 6])
              ListTile(
                leading: _icon(idx, navIndex.value == idx),
                title: Text(dests[idx].$3),
                selected: navIndex.value == idx,
                onTap: () {
                  Navigator.pop(c);
                  goTab(idx);
                },
              ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: squadTheme,
        builder: (context, _, __) => ListenableBuilder(
          listenable: S,
          builder: (context, __) {
            final i = navIndex.value;
            // Tabs are deliberately not const so they rebuild when the theme changes.
            final body = TabFadeThrough(index: i, child: IndexedStack(index: i, children: [GamesTab(), FindTab(), HomeTab(), ChatsTab(), GroupsTab(), NewsTab(), SettingsTab()]));
            return LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 800;
              final extended = box.maxWidth >= 1100;
              final barSel = barItems.indexOf(i);
              return Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  title: const LogoIcon(size: 36),
                  actions: [
                    IconButton(tooltip: 'Help assistant', icon: const Icon(Icons.support_agent), onPressed: () => openAssistant(context)),
                    const NotifBell(),
                    IconButton(
                      tooltip: 'My profile',
                      onPressed: () => openMyProfile(context),
                      icon: S.me == null ? const Icon(Icons.person_outline) : meAvatar(radius: 14),
                    ),
                    const SizedBox(width: 8),
                  ],
                  bottom: const PreferredSize(preferredSize: Size.fromHeight(3), child: GradientBar()),
                ),
                floatingActionButton: i == 3 && !wide
                    ? null
                    : (wide
                        ? FloatingActionButton.extended(
                            heroTag: 'assistantFab',
                            onPressed: () => openAssistant(context),
                            icon: const Icon(Icons.smart_toy_outlined),
                            label: const Text('Ask Assistant'),
                          )
                        : FloatingActionButton(
                            heroTag: 'assistantFab',
                            tooltip: 'Ask the SquadUp Assistant',
                            onPressed: () => openAssistant(context),
                            child: const Icon(Icons.smart_toy_outlined),
                          )),
                body: wide
                    ? Row(children: [
                        NavigationRail(
                          selectedIndex: i,
                          extended: extended,
                          onDestinationSelected: goTab,
                          labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                          backgroundColor: Theme.of(context).cardColor,
                          destinations: [
                            for (var k = 0; k < dests.length; k++)
                              NavigationRailDestination(icon: _icon(k, false), selectedIcon: _icon(k, true), label: Text(dests[k].$3)),
                          ],
                        ),
                        Expanded(child: body),
                      ])
                    : body,
                bottomNavigationBar: wide
                    ? null
                    : NavigationBar(
                        selectedIndex: barSel == -1 ? barItems.length : barSel,
                        onDestinationSelected: (v) => v < barItems.length ? goTab(barItems[v]) : _more(),
                        destinations: [
                          for (final k in barItems) NavigationDestination(icon: _icon(k, false), selectedIcon: _icon(k, true), label: dests[k].$3),
                          const NavigationDestination(icon: Pressable(scale: 0.9, child: Icon(Icons.more_horiz)), selectedIcon: NavPop(Icon(Icons.more_horiz)), label: 'More'),
                        ],
                      ),
              );
            });
          },
        ),
      );
}

/// Which tab of the home shell is showing (0 Home = games list, 1 Find Team, 2 Dashboard, 3 Chats, 4 Groups, 5 News, 6 Settings).
final navIndex = ValueNotifier<int>(0);
void goTab(int i) => navIndex.value = i;

class NotifBell extends StatelessWidget {
  const NotifBell({super.key});
  @override
  Widget build(BuildContext context) {
    final n = S.notificationCount;
    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(isLabelVisible: n > 0, label: Text(n > 99 ? '99+' : '$n'), child: const Icon(Icons.notifications_outlined)),
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: kCard,
        builder: (c) => SafeArea(
          child: ListenableBuilder(
            listenable: S,
            builder: (_, __) {
              final me = S.me;
              final newsN = me == null ? 0 : kNews.where((a) => a.games.any(me.followed.contains)).length;
              final items = <(IconData, String, int)>[
                (Icons.chat_bubble_outline, '${S.totalUnread} unread message${S.totalUnread == 1 ? '' : 's'}', 3),
                (Icons.person_add_alt, '${S.incomingFriendReqs.length} friend request${S.incomingFriendReqs.length == 1 ? '' : 's'}', 2),
                (Icons.how_to_reg_outlined, '${S.pendingApprovals} group join request${S.pendingApprovals == 1 ? '' : 's'} to review', 2),
                (Icons.favorite_border, '$newsN news stor${newsN == 1 ? 'y' : 'ies'} about games you follow', 5),
              ];
              final shown = [
                if (S.totalUnread > 0) items[0],
                if (S.incomingFriendReqs.isNotEmpty) items[1],
                if (S.pendingApprovals > 0) items[2],
                if (newsN > 0) items[3],
              ];
              return Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                if (shown.isEmpty)
                  const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 24), child: Text("You're all caught up 🎮", style: TextStyle(color: kMuted))),
                for (final it in shown)
                  ListTile(
                    leading: Icon(it.$1, color: kAccent),
                    title: Text(it.$2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(c);
                      if (it.$3 == 5) newsMine.value = true;
                      goTab(it.$3);
                    },
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Profile tab ─────────────────────────
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void editUsername(BuildContext context, Profile p) {
    final c = TextEditingController(text: p.username);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Edit username'),
        content: outLabel('Username', TextField(controller: c, autofocus: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.length < 3 || v.contains(' ')) {
                toast('Username must be 3+ characters with no spaces');
              } else if (S.usernameTaken(v, except: p)) {
                toast('Username already taken');
              } else {
                p.username = v;
                S.update();
                Navigator.pop(d);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void editBio(BuildContext context, Profile p) {
    final c = TextEditingController(text: p.bio);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Edit bio'),
        content: outLabel('Bio', TextField(controller: c, maxLines: 4, maxLength: 200, autofocus: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              p.bio = c.text.trim();
              S.update();
              Navigator.pop(d);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void pickAvatar(BuildContext context, Profile p) => showAvatarSheet(context, p);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final p = S.me;
          if (p == null) return const SizedBox();
          final linked = p.linked.entries.where((e) => e.value).map((e) => e.key).toList();
          final mine = S.groupsOf(p);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                pageTitle('Profile'),
                Sec(
                  '${p.first} ${p.last}',
                  Row(children: [
                    GestureDetector(
                      onTap: () => pickAvatar(context, p),
                      child: Stack(children: [
                        Avatar(p.avatar, radius: 38, bytes: p.avatarBytes),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(radius: 12, backgroundColor: kAccent, foregroundColor: Colors.white, child: Icon(Icons.edit, size: 14)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text('@${p.username}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: kAccent, fontSize: 16))),
                          IconButton(visualDensity: VisualDensity.compact, iconSize: 18, onPressed: () => editUsername(context, p), icon: const Icon(Icons.edit)),
                        ]),
                        Text('${p.country}${p.dob == null ? '' : ' · ${ageOf(p.dob!)} yrs'} · ${p.gender}', style: const TextStyle(color: kMuted)),
                      ]),
                    ),
                  ]),
                ),
                if (linked.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final l in linked) Chip(avatar: const Icon(Icons.verified, size: 18, color: kAccent), label: Text('$l${p.linkedVisibility[l] == false ? ' (hidden)' : ''}')),
                    ]),
                  ),
                Sec(
                  'About me',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.bio.isEmpty ? 'Tell other gamers about yourself.' : p.bio, style: TextStyle(color: p.bio.isEmpty ? kMuted : null)),
                    const SizedBox(height: 14),
                    PickField(label: 'Availability', value: p.avail, options: kAvail, onChanged: (v) {
                      p.avail = v;
                      S.update();
                    }),
                  ]),
                  action: IconButton(onPressed: () => editBio(context, p), icon: const Icon(Icons.edit, size: 18)),
                ),
                if (linked.isNotEmpty)
                  Sec(
                    'Verified stats (demo)',
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Demo numbers. Real verified stats need official platform APIs and your authorisation.', style: TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      for (final l in linked)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            const Icon(Icons.verified, size: 18, color: kAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l)),
                            Text('${200 + (l.length * 137) % 1800} hrs · ${kRanks[l.length % 5]}', style: const TextStyle(color: kMuted, fontSize: 13)),
                          ]),
                        ),
                    ]),
                  ),
                Sec('My games', GamesEditor(p: p, onChanged: S.update)),
                Sec('My ranks & roles', RankEditor(p: p, onChanged: S.update)),
                Sec('Gamer type & teammates', PrefsEditor(p: p, onChanged: S.update)),
                Sec('Mic, languages & contact', StyleEditor(p: p, onChanged: S.update)),
                Sec(
                  'My groups',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(p.showGroups ? Icons.visibility : Icons.visibility_off, size: 16, color: kMuted),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p.showGroups ? 'Visible on your public profile' : 'Hidden from your public profile', style: const TextStyle(color: kMuted, fontSize: 12))),
                    ]),
                    const SizedBox(height: 8),
                    if (mine.isEmpty)
                      const Text('You are not in any groups yet. Join or create one in the Groups tab.')
                    else
                      for (final g in mine)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GroupBadge(g, size: 38),
                          title: Text(g.name),
                          subtitle: Text(g.games.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openGroup(context, g),
                        ),
                  ]),
                ),
                Sec('Linked accounts', LinkedEditor(p: p, onChanged: S.update)),
                myStatsSec(p),
                achievementsSec(p),
                Sec(
                  'Privacy',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Choose who can see each part of your profile.', style: TextStyle(color: kMuted)),
                    const SizedBox(height: 12),
                    PrivacyEditor(p: p, onChanged: S.update),
                  ]),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () {
                    logout(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ]),
            ),
          );
        },
      );
}

// ───────────────────────── Search panel & game cards ─────────────────────────
/// Always-available cover art: gradient + icon + title. Real art (Steam CDN or kCoverOverrides) fades in on top.
class GeneratedCover extends StatelessWidget {
  final String game;
  final bool compact;
  const GeneratedCover(this.game, {super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => Container(
        decoration: coverDeco(game, r: 0),
        child: Stack(children: [
          Positioned(right: -6, bottom: -6, child: Icon(gameIcon(game), size: compact ? 30 : 84, color: Colors.white.withAlpha(38))),
          if (compact)
            Center(child: Icon(gameIcon(game), size: 16, color: Colors.white70))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  game.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5, height: 1.15, shadows: [Shadow(blurRadius: 6, color: Colors.black54)]),
                ),
              ),
            ),
        ]),
      );
}

class CoverImage extends StatelessWidget {
  final String game;
  final bool compact;
  const CoverImage(this.game, {super.key, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final asset = kCoverAssets[game];
    final url = asset == null ? coverUrl(game) : null;
    return Stack(fit: StackFit.expand, children: [
      GeneratedCover(game, compact: compact),
      if (asset != null)
        Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
      if (url != null)
        Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
    ]);
  }
}

class GameBadge extends StatelessWidget {
  final String text;
  final Color color;
  const GameBadge(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(color: color.computeLuminance() > 0.45 ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      );
}

class GameCard extends StatelessWidget {
  final String game;
  final VoidCallback? onTap;
  final bool selected;
  const GameCard(this.game, {super.key, this.onTap, this.selected = false});
  @override
  Widget build(BuildContext context) {
    final soon = kUpcoming[game];
    return Pressable(child: Material(
      color: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => openGame(context, game),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kAccent : Colors.transparent, width: 2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                CoverImage(game),
                if (soon != null) const Positioned(top: 8, left: 8, child: GameBadge('COMING SOON', Colors.amber)),
                if (kNew.contains(game)) const Positioned(top: 8, left: 8, child: GameBadge('NEW', kAccent)),
                Positioned(top: 2, right: 2, child: FollowHeart(game)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(game, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(soon != null ? Icons.event : Icons.people, size: 13, color: soon != null ? Colors.amber : kAccent),
                  const SizedBox(width: 4),
                  Expanded(child: Text(soon != null ? soon : '${onlineCount(game)} players', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: soon != null ? Colors.amber : kMuted))),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    ));
  }
}

// ───────────────────────── Find team tab ─────────────────────────
class FindTab extends StatefulWidget {
  const FindTab({super.key});
  @override
  State<FindTab> createState() => _FindTabState();
}

class _FindTabState extends State<FindTab> {
  String fGame = 'Any', fPlat = 'Any', fRank = 'Any', fAvail = 'Any', fRegion = 'Any', fMinRank = 'Any', fType = 'Any', fMic = 'Any';
  RangeValues fAge = const RangeValues(13, 60);
  final q = TextEditingController();

  List<Player> get results {
    final t = q.text.trim().toLowerCase();
    return kPlayers
        .where((p) =>
            (t.isEmpty ||
                p.tag.toLowerCase().contains(t) ||
                p.real.toLowerCase().contains(t) ||
                p.games.any((g) => g.toLowerCase().contains(t))) &&
            (fGame == 'Any' || p.games.contains(fGame)) &&
            (fPlat == 'Any' || p.platform == fPlat) &&
            (fRank == 'Any' || p.rank == fRank) &&
            (fMinRank == 'Any' || fGame == 'Any' || rankIndex(fGame, playerRank(p, fGame)) >= rankIndex(fGame, fMinRank)) &&
            (fType == 'Any' || p.gamerTypes.contains(fType)) &&
            (fMic == 'Any' || (fMic == 'Has a mic') == p.hasMic) &&
            (S.me == null || !hiddenByPrefs(S.me!, p)) &&
            (fAvail == 'Any' || p.avail == fAvail) &&
            (fRegion == 'Any' || p.region == fRegion) &&
            p.age >= fAge.start.round() &&
            p.age <= fAge.end.round())
        .toList();
  }

  Widget filter(String label, String v, List<String> o, ValueChanged<String> cb) => SizedBox(
        width: 200,
        child: PickField(label: label, value: v, options: ['Any', ...o], onChanged: (x) => setState(() => cb(x))),
      );

  @override
  Widget build(BuildContext context) {
    final games = <String>{...kPopular, for (final p in kPlayers) ...p.games}.toList()..sort();
    return ListenableBuilder(
      listenable: S,
      builder: (context, _) {
        final r = ranked(results);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              pageTitle('Find Team'),
              searchField(q, (_) => setState(() {})),
            ]),
          ),
          Expanded(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.tune, color: kAccent),
                        title: const Text('Filters'),
                        subtitle: Text('${r.length} matching players'),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            filter('Game', fGame, games, (x) {
                              fGame = x;
                              fMinRank = 'Any';
                            }),
                            filter('Platform', fPlat, kPlatforms, (x) => fPlat = x),
                            filter('Rank / skill', fRank, kRanks, (x) => fRank = x),
                            if (fGame != 'Any' && ladderOf(fGame) != null) filter('Min. rank in $fGame', fMinRank, ladderOf(fGame)!, (x) => fMinRank = x),
                            filter('Gamer type', fType, kGamerTypes, (x) => fType = x),
                            filter('Microphone', fMic, const ['Has a mic', 'No mic'], (x) => fMic = x),
                            filter('Availability', fAvail, kAvail, (x) => fAvail = x),
                            filter('Region', fRegion, kRegions, (x) => fRegion = x),
                          ]),
                          const SizedBox(height: 12),
                          if (S.me != null && S.me!.avoids.isNotEmpty)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Show players my preferences hide'),
                              subtitle: Text('${hiddenCount(S.me!)} hidden'),
                              value: S.me!.showFiltered,
                              onChanged: (v) {
                                S.me!.showFiltered = v;
                                S.update();
                              },
                            ),
                          Text('Age range: ${fAge.start.round()} – ${fAge.end.round()}${fAge.end.round() >= 60 ? '+' : ''}'),
                          RangeSlider(values: fAge, min: 13, max: 60, divisions: 47, onChanged: (v) => setState(() => fAge = v)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                fGame = fPlat = fRank = fAvail = fRegion = fMinRank = fType = fMic = 'Any';
                                fAge = const RangeValues(13, 60);
                                q.clear();
                              }),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    const Expanded(child: Text('Players for you', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                    Text('${r.length} found', style: const TextStyle(color: kMuted)),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: r.isEmpty
                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No players match. Try changing your search or filters.', textAlign: TextAlign.center)))
                      : PlayerGrid(r),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

/// Responsive grid whose rows size to their content, so card text can never overflow or be cut off.
class FlowGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  const FlowGrid(this.children, {super.key, this.minWidth = 380});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = (box.maxWidth / minWidth).floor().clamp(1, 4).toInt();
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
                ],
              ]),
            ),
          ));
        }
        return Column(children: rows);
      });
}

class PlayerGrid extends StatelessWidget {
  final List<(Player, int)> items;
  const PlayerGrid(this.items, {super.key});
  @override
  Widget build(BuildContext context) => FlowGrid([for (final e in items) PlayerCard(e.$1, e.$2)]);
}

class MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  const MiniButton({super.key, required this.label, required this.icon, this.onTap, this.filled = true});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    final fg = on && filled ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(on ? 255 : 120);
    return Ink(
      decoration: BoxDecoration(
        gradient: on && filled ? kBrandGradient : null,
        color: on && filled ? null : kField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  final Player p;
  final int score;
  const PlayerCard(this.p, this.score, {super.key});

  Widget chip(String t, IconData icon) => infoChip(t, icon: icon);

  @override
  Widget build(BuildContext context) {
    final inv = S.invited.contains(p.tag);
    final friend = S.friends.contains(p.tag);
    final showTag = canSee(p, 'Gamertag');
    final showGames = canSee(p, 'Games') && p.games.isNotEmpty;
    final main = showGames ? p.games.first : null;
    final showStyle = canSee(p, 'Play style & comms');
    final showAct = canSee(p, 'Activity & reliability');
    final rank = main == null || !canSee(p, 'Rank') ? null : playerRank(p, main);
    final details = [
      if (showTag && p.real.isNotEmpty) p.real,
      if (canSee(p, 'Age / DOB')) '${p.age} yrs',
      p.region,
    ].join(' · ');
    final status = p.status[0].toUpperCase() + p.status.substring(1);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: statusColor(p.status)),
        const SizedBox(width: 4),
        Text(status, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ]),
    );
    return Pressable(child: Material(
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
      child: InkWell(
        onTap: () => openPlayer(context, p),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top half: the main game's banner
          if (main != null)
            gameBanner(main, h: 120, corner: pill)
          else
            SizedBox(
              height: 120,
              child: Stack(fit: StackFit.expand, children: [
                Container(decoration: coverDeco(p.tag, r: 0), child: const Center(child: Icon(Icons.lock_outline, color: Colors.white54, size: 30))),
                Positioned(left: 14, bottom: 10, child: const Text('Games hidden', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                Positioned(top: 10, right: 10, child: pill),
              ]),
            ),
          Container(height: 3, color: p.themeColor),
          // Bottom half: the player's details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Avatar(p.avatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(showTag ? p.tag : 'Anonymous player', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              MatchBar(score),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                chip(p.platform, Icons.sports_esports),
                if (rank != null) RankBadge(main!, rank, linked: p.verified) else chip(p.rank, Icons.military_tech),
                chip(p.avail, Icons.schedule),
                if (showStyle) chip(p.playStyle, Icons.flag_outlined),
                if (showStyle) chip(p.role, Icons.shield_outlined),
                if (showStyle) chip(p.hasMic ? 'Mic' : 'No mic', p.hasMic ? Icons.mic : Icons.mic_off),
              ]),
              if (showStyle && p.gamerTypes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final t in p.gamerTypes.take(3)) chip(t, Icons.sports_esports_outlined)]),
              ],
              if (S.me != null && whyMatch(S.me!, p).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Why you match: ${whyMatch(S.me!, p).join(' · ')}', style: const TextStyle(color: kAccentLight, fontSize: 12)),
              ],
              if (showAct) ...[
                const SizedBox(height: 8),
                Text('${p.lastActive} · their time ${p.localTime} · ${p.reliability}% reliable', style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              Text(canSee(p, 'Bio') ? p.bio : 'Bio is private', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
                  MiniButton(label: friend ? 'In squad' : (inv ? 'Requested' : 'Send Request'), icon: friend ? Icons.check : (inv ? Icons.hourglass_top : Icons.person_add_alt_1), filled: false, onTap: friend || inv ? null : () => S.invite(p)),
                  MiniButton(label: 'Message', icon: Icons.chat_bubble_outline, onTap: () => openChat(context, S.startChat(p))),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    ));
  }
}

// ───────────────────────── Settings ─────────────────────────
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  Profile? get p => S.me;

  Future<void> editAccount(Profile profile) async {
    final first = TextEditingController(text: profile.first);
    final last = TextEditingController(text: profile.last);
    final email = TextEditingController(text: profile.email);
    final username = TextEditingController(text: profile.username);
    final bio = TextEditingController(text: profile.bio);
    final saved = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Edit profile details'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              tf(first, 'First name'),
              tf(last, 'Last name'),
              tf(email, 'Email', type: TextInputType.emailAddress),
              tf(username, 'Gamertag / username'),
              tf(bio, 'Bio', lines: 3, max: 200),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      if (username.text.trim().length < 3 || username.text.contains(' ')) {
        toast('Gamertag must be at least 3 characters and contain no spaces');
        return;
      }
      if (S.usernameTaken(username.text, except: profile)) {
        toast('That gamertag is already taken');
        return;
      }
      profile.first = first.text.trim();
      profile.last = last.text.trim();
      profile.email = email.text.trim();
      profile.username = username.text.trim();
      profile.bio = bio.text.trim();
      S.update();
    }
  }

  Future<void> changePassword(Profile profile) async {
    final old = TextEditingController(), next = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Change password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          outLabel('Current password', TextField(controller: old, obscureText: true)),
          const SizedBox(height: 14),
          outLabel('New password', TextField(controller: next, obscureText: true)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Update')),
        ],
      ),
    );
    if (saved == true) {
      if (old.text != profile.password) {
        toast('Current password is incorrect');
        return;
      }
      if (next.text.length < 8) {
        toast('New password must be at least 8 characters');
        return;
      }
      profile.password = next.text;
      S.update();
      toast('Password changed locally');
    }
  }

  Future<void> deleteAccount(Profile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This removes the account from this prototype session. A production app needs a secure backend deletion endpoint.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      S.users.remove(profile);
      logout(context);
    }
  }

  void infoDialog(String title, String message) => showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
        ),
      );

  Widget visibilityRow(Profile profile, String label, String key) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PickField(
          label: label,
          value: profile.privacy[key] ?? 'Public',
          options: kVis,
          onChanged: (v) {
            profile.privacy[key] = v;
            if (key == 'Gamertag') profile.anonymousGamertag = v != 'Public';
            S.update();
          },
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final profile = p;
          if (profile == null) return const Center(child: Text('Log in to view settings.'));
          final dark = squadTheme.value == ThemeMode.dark;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
                pageTitle('Settings'),
                Sec(
                  'Appearance',
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    subtitle: Text(dark ? 'Dark appearance enabled' : 'Light appearance enabled'),
                    value: dark,
                    onChanged: (v) => squadTheme.value = v ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
                Sec(
                  'Account',
                  Column(children: [
                    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.photo_camera_outlined), title: const Text('Profile picture'), subtitle: const Text('Upload a photo from your device or pick an avatar'), trailing: const Icon(Icons.chevron_right), onTap: () => showAvatarSheet(context, profile)),
                    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline), title: const Text('My profile, games & ranking'), subtitle: const Text('Rate each game from rarely played to main game'), trailing: const Icon(Icons.chevron_right), onTap: () => openMyProfile(context)),
                    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_outlined), title: const Text('Edit profile details'), subtitle: const Text('Name, email, gamertag and bio'), onTap: () => editAccount(profile)),
                    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.lock_outline), title: const Text('Change password'), onTap: () => changePassword(profile)),
                    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Delete account'), onTap: () => deleteAccount(profile)),
                  ]),
                ),
                Sec(
                  'Privacy',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Choose who can see each part of your profile.', style: TextStyle(color: kMuted)),
                    const SizedBox(height: 12),
                    visibilityRow(profile, 'Who can see my gamertag', 'Gamertag'),
                    visibilityRow(profile, 'Who can see my games', 'Games'),
                    visibilityRow(profile, 'Who can see my age', 'Age / DOB'),
                    visibilityRow(profile, 'Who can see my bio', 'Bio'),
                    visibilityRow(profile, 'Who can see my game stats', 'Game stats'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use anonymous gamertag'),
                      subtitle: const Text('People outside the audience you choose see you as "Anonymous player"'),
                      value: profile.anonymousGamertag,
                      onChanged: (v) {
                        profile.anonymousGamertag = v;
                        final cur = profile.privacy['Gamertag'] ?? 'Public';
                        profile.privacy['Gamertag'] = v ? (cur == 'Public' ? 'Friends Only' : cur) : 'Public';
                        S.update();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Show groups I'm in on my profile"),
                      value: profile.showGroups,
                      onChanged: (v) {
                        profile.showGroups = v;
                        S.update();
                      },
                    ),
                  ]),
                ),
                Sec(
                  'Linked Accounts',
                  Column(children: [
                    const Text('Connections are demo toggles at the moment. Verified stats require official platform APIs and user authorisation.', style: TextStyle(color: kMuted)),
                    const SizedBox(height: 8),
                    LinkedEditor(p: profile, onChanged: S.update),
                    const Divider(),
                    for (final e in profile.linked.entries)
                      if (e.value)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Show ${e.key} on profile'),
                          value: profile.linkedVisibility[e.key] ?? true,
                          onChanged: (v) {
                            profile.linkedVisibility[e.key] = v;
                            S.update();
                          },
                        ),
                  ]),
                ),
                Sec(
                  'Notifications',
                  Column(children: [
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Push notifications'), value: profile.pushNotifications, onChanged: (v) { profile.pushNotifications = v; S.update(); }),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Email notifications'), value: profile.emailNotifications, onChanged: (v) { profile.emailNotifications = v; S.update(); }),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show online status'), value: profile.showOnlineStatus, onChanged: (v) { profile.showOnlineStatus = v; S.update(); }),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Allow friend requests'), value: profile.allowFriendRequests, onChanged: (v) { profile.allowFriendRequests = v; S.update(); }),
                  ]),
                ),
                ...settingsMore(context, profile),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  onPressed: () {
                    logout(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ]),
            ),
          );
        },
      );
}

// ───────────────────────── Games tab & game players ─────────────────────────
class GamesTab extends StatefulWidget {
  const GamesTab({super.key});
  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  final q = TextEditingController();
  String f = 'All';
  @override
  Widget build(BuildContext context) {
    final qText = q.text.trim().toLowerCase();
    final games = popularGames().where((g) {
      if (qText.isNotEmpty && !g.toLowerCase().contains(qText)) return false;
      switch (f) {
        case 'Released':
          return !kUpcoming.containsKey(g);
        case 'New':
          return kNew.contains(g);
        case 'Upcoming':
          return kUpcoming.containsKey(g);
        default:
          return true;
      }
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          pageTitle('Games'),
          searchField(q, (_) => setState(() {})),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final o in const ['All', 'Released', 'New', 'Upcoming'])
              ChoiceChip(label: Text(o), selected: f == o, onSelected: (_) => setState(() => f = o)),
          ]),
        ]),
      ),
      Expanded(
        child: games.isEmpty
            ? const Center(child: Text('No games match your search.', style: TextStyle(color: kMuted)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisExtent: 192, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: games.length,
                itemBuilder: (_, i) => GameCard(games[i]),
              ),
      ),
    ]);
  }
}

class FollowHeart extends StatelessWidget {
  final String game;
  const FollowHeart(this.game, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final on = S.me?.followed.contains(game) ?? false;
          return IconButton(
            tooltip: on ? 'Unfollow $game' : 'Follow $game',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            iconSize: 18,
            onPressed: () => S.toggleFollow(game),
            icon: Icon(on ? Icons.favorite : Icons.favorite_border, color: on ? Colors.pinkAccent : Colors.white),
          );
        },
      );
}

void openNewsFor(BuildContext context, String game) {
  newsGame.value = game;
  Navigator.of(context).popUntil((r) => r.isFirst);
  goTab(5);
}

class GamePlayersScreen extends StatelessWidget {
  final String game;
  const GamePlayersScreen(this.game, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(game, overflow: TextOverflow.ellipsis)),
        body: ListenableBuilder(
          listenable: S,
          builder: (context, _) {
            final r = ranked(playersOf(game));
            final following = S.me?.followed.contains(game) ?? false;
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(spacing: 10, runSpacing: 8, children: [
                    following
                        ? FilledButton.icon(onPressed: () => S.toggleFollow(game), icon: const Icon(Icons.favorite), label: const Text('Following'))
                        : OutlinedButton.icon(onPressed: () => S.toggleFollow(game), icon: const Icon(Icons.favorite_border), label: const Text('Follow game')),
                    OutlinedButton.icon(
                      onPressed: () => openNewsFor(context, game),
                      icon: const Icon(Icons.newspaper),
                      label: const Text('News about this game'),
                    ),
                    if (S.me?.showBuyLinks ?? true)
                      OutlinedButton.icon(
                        onPressed: () => showBuySheet(context, game),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(kUpcoming.containsKey(game) ? 'Pre-order' : (S.me?.games.contains(game) ?? false) ? 'Where to buy' : "Don't own it? Where to buy"),
                      ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 150,
                      child: Stack(fit: StackFit.expand, children: [
                        CoverImage(game),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(game, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(kUpcoming.containsKey(game) ? 'Releases ${kUpcoming[game]} · ${r.length} on SquadUp waiting' : '${onlineCount(game)} players · ${r.length} on SquadUp', style: const TextStyle(color: Colors.white70)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: r.isEmpty
                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No players found for this game yet.', style: TextStyle(color: kMuted))))
                      : PlayerGrid(r),
                ),
              ),
            ]);
          },
        ),
      );
}

// ───────────────────────── Other player's public profile ─────────────────────────
class PlayerProfileScreen extends StatelessWidget {
  final Player p;
  const PlayerProfileScreen(this.p, {super.key});

  Widget locked(String t) => Row(children: [
        const Icon(Icons.lock_outline, size: 16, color: kMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(color: kMuted))),
      ]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final me = S.me;
          final score = me == null ? 0 : matchScore(me, p);
          final friend = S.friends.contains(p.tag);
          final inv = S.invited.contains(p.tag);
          final showAge = canSee(p, 'Age / DOB');
          return Scaffold(
            appBar: AppBar(title: Text(canSee(p, 'Gamertag') ? p.tag : 'Anonymous player'), actions: [PlayerMenu(p)]),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (canSee(p, 'Games') && p.games.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(children: [gameBanner(p.games.first, h: 150), Container(height: 4, color: p.themeColor)]),
                      ),
                    ),
                  Sec(
                    canSee(p, 'Gamertag') ? (p.real.isEmpty ? p.tag : p.real) : 'Anonymous player',
                    Column(children: [
                      Row(children: [
                        Avatar(p.avatar, radius: 40, status: p.status),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(canSee(p, 'Gamertag') ? '@${p.tag}' : 'Gamertag hidden', style: const TextStyle(color: kAccent, fontSize: 16)),
                            Text(p.status, style: TextStyle(color: statusColor(p.status), fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(showAge ? '${p.age} yrs · ${p.region} · ${p.gender}${p.pronouns.isEmpty ? '' : ' · ${p.pronouns}'}' : 'Age, region and gender are not public', style: const TextStyle(color: kMuted)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerLeft, child: SizedBox(width: 240, child: MatchBar(score))),
                    ]),
                  ),
                  Sec(
                    'Linked platforms',
                    canSee(p, 'Gamertag')
                        ? Wrap(spacing: 8, children: [Chip(avatar: const Icon(Icons.verified, size: 18, color: kAccent), label: Text(p.platform))])
                        : locked('Linked platforms are not public'),
                  ),
                  Sec('About', canSee(p, 'Bio') ? Text(p.bio) : locked('Bio is not public')),
                  Sec(
                    'Games',
                    canSee(p, 'Games')
                        ? Column(children: [
                            for (var i = 0; i < p.games.length; i++)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(p.games[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                                    if (me != null && me.games.contains(p.games[i])) const Text('Shared', style: TextStyle(color: kAccent, fontSize: 12)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    RatingDots(p.rating(i), size: 10),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(kRatingLabels[p.rating(i) - 1], style: const TextStyle(color: kMuted, fontSize: 13))),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text('“${p.note(i)}”', style: const TextStyle(fontStyle: FontStyle.italic, color: kMuted)),
                                ]),
                              ),
                          ])
                        : locked('Games are not public'),
                  ),
                  ...playerTagSecs(p),
                  ...playerExtraSecs(context, p),
                  playerStatsSec(p),
                  commendSec(p),
                  if (!canSee(p, 'Groups'))
                    Sec('Groups', locked('Groups are not public'))
                  else if (S.groupsOf(p).isNotEmpty)
                    Sec(
                      'Groups',
                      Column(children: [
                        for (final g in S.groupsOf(p))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: GroupBadge(g, size: 36),
                            title: Text(g.name),
                            subtitle: Text(g.isPublic ? 'Public group' : 'Private group'),
                            onTap: () => openGroup(context, g),
                          ),
                      ]),
                    ),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: bigBtn(),
                        onPressed: friend || inv ? null : () => S.invite(p),
                        icon: Icon(friend ? Icons.check : (inv ? Icons.hourglass_top : Icons.person_add_alt_1), size: 18),
                        label: Text(friend ? 'In your squad' : (inv ? 'Invited' : 'Send Invite')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: () => openChat(context, S.startChat(p)),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Start Chat'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          );
        },
      );
}

// ───────────────────────── Groups ─────────────────────────
class GroupBadge extends StatelessWidget {
  final Group g;
  final double size;
  const GroupBadge(this.g, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) {
    final words = g.name.split(' ').where((w) => w.isNotEmpty).toList();
    final ini = words.take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: coverDeco(g.name, r: size / 4),
      child: Text(ini, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.38)),
    );
  }
}

Widget detailRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: kAccent),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
    );

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});
  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final q = TextEditingController();
  String fGame = 'Any', fVis = 'Any', fPlat = 'Any', fRegion = 'Any';
  bool mineOnly = false;
  bool communities = false; // Groups and Communities are separate sections

  List<Group> get results {
    final t = q.text.trim().toLowerCase();
    return S.groups
        .where((g) =>
            g.isCommunity == communities &&
            (t.isEmpty || g.name.toLowerCase().contains(t) || g.games.any((x) => x.toLowerCase().contains(t))) &&
            (fGame == 'Any' || g.games.contains(fGame)) &&
            (fVis == 'Any' || (fVis == 'Public') == g.isPublic) &&
            (fPlat == 'Any' || g.platform == 'Any' || g.platform == fPlat) &&
            (fRegion == 'Any' || g.region == 'Any' || g.region == fRegion) &&
            (!mineOnly || gIsMember(g)))
        .toList();
  }

  Widget filter(String label, String v, List<String> o, ValueChanged<String> cb) => SizedBox(
        width: 200,
        child: PickField(label: label, value: v, options: ['Any', ...o], onChanged: (x) => setState(() => cb(x))),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          final r = results;
          final games = <String>{for (final g in S.groups) if (g.isCommunity == communities) ...g.games}.toList()..sort();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: pageTitle(communities ? 'Communities' : 'Groups')),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupScreen(community: communities))),
                    icon: const Icon(Icons.add),
                    label: Text(communities ? 'Create community' : 'Create group'),
                  ),
                ]),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Groups'), icon: Icon(Icons.groups_outlined)),
                    ButtonSegment(value: true, label: Text('Communities'), icon: Icon(Icons.diversity_3)),
                  ],
                  selected: {communities},
                  onSelectionChanged: (v) => setState(() {
                    communities = v.first;
                    fGame = 'Any';
                  }),
                ),
                const SizedBox(height: 10),
                searchField(q, (_) => setState(() {})),
              ]),
            ),
            Expanded(
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Material(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
                        clipBehavior: Clip.antiAlias,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: const Icon(Icons.tune, color: kAccent),
                            title: const Text('Filters'),
                            subtitle: Text(communities ? '${r.length} communit${r.length == 1 ? 'y' : 'ies'}' : '${r.length} group${r.length == 1 ? '' : 's'}'),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Wrap(spacing: 12, runSpacing: 12, children: [
                                filter('Game', fGame, games, (x) => fGame = x),
                                SizedBox(width: 200, child: PickField(label: 'Public / private', value: fVis, options: const ['Any', 'Public', 'Private'], onChanged: (x) => setState(() => fVis = x))),
                                filter('Platform', fPlat, kPlatforms, (x) => fPlat = x),
                                filter('Region', fRegion, kRegions, (x) => fRegion = x),
                              ]),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => setState(() {
                                    fGame = fVis = fPlat = fRegion = 'Any';
                                    q.clear();
                                  }),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset filters'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: [
                        ChoiceChip(label: Text('All ${communities ? 'communities' : 'groups'}'), selected: !mineOnly, onSelected: (_) => setState(() => mineOnly = false)),
                        ChoiceChip(label: Text('My ${communities ? 'communities' : 'groups'}'), selected: mineOnly, onSelected: (_) => setState(() => mineOnly = true)),
                      ]),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: r.isEmpty
                        ? Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No ${communities ? 'communities' : 'groups'} match. Try different filters or create your own.', textAlign: TextAlign.center)))
                        : FlowGrid([for (final g in r) GroupCard(g)], minWidth: 420),
                  ),
                ),
              ]),
            ),
          ]);
        },
      );
}

class GroupCard extends StatelessWidget {
  final Group g;
  const GroupCard(this.g, {super.key});
  @override
  Widget build(BuildContext context) {
    final member = gIsMember(g);
    final pending = g.requests.any((r) => identical(r, S.me));
    final descVisible = member || g.canView('Description');
    final gamesVisible = member || g.canView('Games');
    return Pressable(child: Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openGroup(context, g),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GroupBadge(g, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (g.isCommunity) infoChip('Community', icon: Icons.diversity_3, color: kAccent),
                    infoChip(g.isPublic ? 'Public' : 'Private', icon: g.isPublic ? Icons.public : Icons.lock_outline),
                    Text('${g.members.length}${g.maxMembers == null ? '' : ' / ${g.maxMembers}'} members', style: const TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            descVisible
                ? Text(g.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5))
                : lockedRow('Description is hidden'),
            const SizedBox(height: 10),
            gamesVisible
                ? Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final x in g.games.take(3)) infoChip(x, lead: gameThumb(x, w: 20, h: 20)),
                    if (g.games.length > 3) infoChip('+${g.games.length - 3} more'),
                  ])
                : lockedRow('Games are hidden'),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              infoChip(g.platform == 'Any' ? 'All platforms' : g.platform, icon: Icons.devices),
              infoChip(g.region == 'Any' ? 'Worldwide' : g.region, icon: Icons.place_outlined),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: member
                  ? MiniButton(label: 'Open', icon: Icons.open_in_new, filled: false, onTap: () => openGroup(context, g))
                  : pending
                      ? const MiniButton(label: 'Requested', icon: Icons.hourglass_top, onTap: null)
                      : g.isFull
                          ? const MiniButton(label: 'Full', icon: Icons.block, onTap: null)
                          : MiniButton(label: g.isPublic ? 'Join' : 'Request to join', icon: g.isPublic ? Icons.login : Icons.lock_open, onTap: () => S.joinGroup(g)),
            ),
          ]),
        ),
      ),
    ));
  }
}

class GroupScreen extends StatelessWidget {
  final Group g;
  const GroupScreen(this.g, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) {
          if (!S.groups.contains(g)) {
            return Scaffold(appBar: AppBar(), body: const Center(child: Text('This group no longer exists.')));
          }
          final tabs = <(String, Widget)>[
            ('Overview', GroupOverview(g)),
            (g.isCommunity ? 'Channels' : 'Group chat', g.isCommunity ? CommunityChatTab(g) : GroupChatTab(g)),
            ('Announcements', GroupNewsTab(g)),
            if (g.isCommunity) ('Events', CommunityEventsTab(g)),
            ('Members', GroupMembersTab(g)),
            ('Squad sheet', SquadSheetTab(g)),
          ];
          return DefaultTabController(
            key: ValueKey('${g.id}-${tabs.length}'),
            length: tabs.length,
            child: Scaffold(
              appBar: AppBar(
                title: Row(children: [
                  GroupBadge(g, size: 32),
                  const SizedBox(width: 10),
                  Expanded(child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Icon(g.isPublic ? Icons.public : Icons.lock_outline, size: 18, color: kMuted),
                ]),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [for (final t in tabs) Tab(text: t.$1)],
                ),
              ),
              body: TabBarView(children: [for (final t in tabs) t.$2]),
            ),
          );
        },
      );
}

Future<void> confirmDeleteGroup(BuildContext context, Group g) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: kCard,
      title: const Text('Delete group?'),
      content: Text('"${g.name}" and its chat will be removed for everyone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    Navigator.pop(context);
    S.deleteGroup(g);
  }
}

class GroupOverview extends StatelessWidget {
  final Group g;
  const GroupOverview(this.g, {super.key});
  @override
  Widget build(BuildContext context) {
    final member = gIsMember(g);
    final pending = g.requests.any((r) => identical(r, S.me));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Sec('About', member || g.canView('Description') ? Text(g.description.isEmpty ? 'No description yet.' : g.description) : lockedRow('The owner has hidden the description from non-members')),
          Sec(
            'Games (${g.games.length})',
            member || g.canView('Games')
                ? Column(children: [
                    for (final x in g.games)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: gameThumb(x, w: 56, h: 36),
                        title: Text(x),
                        subtitle: kUpcoming.containsKey(x) ? Text('Upcoming · ${kUpcoming[x]}', style: const TextStyle(color: Colors.amber)) : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => openGame(context, x),
                      ),
                  ])
                : lockedRow('The owner has hidden the games from non-members'),
          ),
          if (g.isCommunity)
            Sec('Rules', member || g.canView('Rules') ? Text(g.rules.isEmpty ? 'No rules yet.' : g.rules) : lockedRow('The owner has hidden the rules from non-members')),
          Sec(
            g.isCommunity ? 'Community details' : 'Details',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              detailRow(g.isPublic ? Icons.public : Icons.lock_outline, g.isPublic ? 'Public group: anyone can join' : 'Private group: members join by request'),
              detailRow(Icons.devices, g.platform == 'Any' ? 'All platforms' : g.platform),
              detailRow(Icons.place_outlined, g.region == 'Any' ? 'Worldwide' : g.region),
              detailRow(g.isCommunity ? Icons.diversity_3 : Icons.groups, g.isCommunity ? 'Community' : 'Group'),
              detailRow(Icons.people_outline, '${g.members.length}${g.maxMembers == null ? '' : ' of ${g.maxMembers}'} members${g.isFull ? ' (full)' : ''}'),
              detailRow(Icons.shield_outlined, 'Owner: ${g.owner.name}'),
            ]),
          ),
          if (!member)
            FilledButton.icon(
              style: bigBtn(),
              onPressed: pending || g.isFull ? null : () => S.joinGroup(g),
              icon: Icon(pending ? Icons.hourglass_top : (g.isPublic ? Icons.login : Icons.lock_open)),
              label: Text(g.isFull ? 'Full: no spaces left' : (pending ? 'Request sent' : (g.isPublic ? 'Join ${g.isCommunity ? 'community' : 'group'}' : 'Request to join'))),
            )
          else if (!gIsOwner(g))
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                S.leaveGroup(g);
                toast('You left ${g.name}');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Leave group'),
            ),
          if (gIsOwner(g)) ...[
            const SizedBox(height: 16),
            Sec(
              '${g.isCommunity ? 'Community' : 'Group'} settings (owner)',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public group'),
                  subtitle: const Text('Public: anyone can join. Private: members join by request.'),
                  value: g.isPublic,
                  onChanged: (v) {
                    g.isPublic = v;
                    S.update();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Member limit'),
                  subtitle: Text(g.maxMembers == null ? 'No limit' : '${g.maxMembers} members (${g.members.length} now)'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => editLimitDialog(context, g),
                ),
                if (g.isCommunity) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.rule),
                    title: const Text('Community rules'),
                    subtitle: Text(g.rules.isEmpty ? 'No rules yet' : g.rules, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => editRulesDialog(context, g),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('New members must accept the rules before chatting'),
                    value: g.rulesRequired,
                    onChanged: (v) {
                      g.rulesRequired = v;
                      S.update();
                    },
                  ),
                ],
                const Divider(),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('What non-members can see', style: TextStyle(fontWeight: FontWeight.bold))),
                for (final k in g.show.keys.toList())
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(k),
                    value: g.show[k]!,
                    onChanged: (v) {
                      g.show[k] = v;
                      S.update();
                    },
                  ),
                const Divider(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, minimumSize: const Size.fromHeight(46)),
                  onPressed: () => confirmDeleteGroup(context, g),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete group'),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class GroupChatTab extends StatefulWidget {
  final Group g;
  final List<Post>? posts; // a community channel's messages (defaults to the group chat)
  final String hint;
  const GroupChatTab(this.g, {super.key, this.posts, this.hint = 'Message the group…'});
  @override
  State<GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends State<GroupChatTab> {
  final c = TextEditingController();
  final sc = ScrollController();

  void send() {
    final t = c.text.trim();
    if (t.isEmpty) return;
    c.clear();
    S.groupSay(widget.g, t, into: widget.posts);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final posts = widget.posts ?? g.chat;
    if (!gIsMember(g)) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('Join this group to read and send messages')));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc.hasClients) sc.jumpTo(sc.position.maxScrollExtent);
    });
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(children: [
          Expanded(
            child: posts.isEmpty
                ? const Center(child: Text('No messages yet. Say hi 👋', style: TextStyle(color: kMuted)))
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (_, i) {
                      final m = posts[i];
                      final mine = identical(m.who, S.me);
                      final av = whoAvatar(m.who, radius: 14);
                      final bubble = Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 340),
                          decoration: BoxDecoration(color: mine ? kAccent : kField, borderRadius: BorderRadius.circular(16)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            if (!mine) Text(whoName(m.who), style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(m.text, style: TextStyle(color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                            Align(alignment: Alignment.centerRight, child: Text(fmtTime(m.t), style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : kMuted))),
                          ]),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: mine ? [bubble, const SizedBox(width: 8), av] : [av, const SizedBox(width: 8), bubble],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: gCanChat(g)
                  ? Row(children: [
                      Expanded(child: TextField(controller: c, onSubmitted: (_) => send(), decoration: InputDecoration(hintText: widget.hint))),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: send, icon: const Icon(Icons.send)),
                    ])
                  : Padding(padding: const EdgeInsets.all(8), child: lockedRow('You do not have permission to send messages in this group')),
            ),
          ),
        ]),
      ),
    );
  }
}

class GroupNewsTab extends StatefulWidget {
  final Group g;
  const GroupNewsTab(this.g, {super.key});
  @override
  State<GroupNewsTab> createState() => _GroupNewsTabState();
}

class _GroupNewsTabState extends State<GroupNewsTab> {
  final c = TextEditingController();

  void post() {
    final t = c.text.trim();
    if (t.isEmpty) return;
    c.clear();
    S.announce(widget.g, t);
    toast('Announcement posted');
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final member = gIsMember(g);
    if (!member && !g.canView('Announcements')) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('The owner has hidden announcements from non-members')));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (gCanAnnounce(g))
            Sec(
              'Post an announcement',
              Column(children: [
                TextField(controller: c, maxLines: 3, maxLength: 300, decoration: const InputDecoration(hintText: 'Share news, rules or event times with the group…')),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: post, icon: const Icon(Icons.campaign_outlined), label: const Text('Post'))),
              ]),
            )
          else if (member)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: lockedRow('Only owners and admins can post announcements')),
          if (g.news.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No announcements yet.', style: TextStyle(color: kMuted))))
          else
            for (final n in g.news)
              Sec(
                '',
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    whoAvatar(n.who, radius: 14),
                    const SizedBox(width: 10),
                    Expanded(child: Text(whoName(n.who), style: const TextStyle(fontWeight: FontWeight.bold))),
                    infoChip(g.memberOf(n.who)?.role == 'owner' ? 'Owner' : 'Admin', icon: Icons.shield_outlined),
                    const SizedBox(width: 8),
                    Text(fmtTime(n.t), style: const TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 10),
                  Text(n.text),
                ]),
              ),
        ]),
      ),
    );
  }
}

class GroupMembersTab extends StatefulWidget {
  final Group g;
  const GroupMembersTab(this.g, {super.key});
  @override
  State<GroupMembersTab> createState() => _GroupMembersTabState();
}

class _GroupMembersTabState extends State<GroupMembersTab> {
  Group get g => widget.g;
  final q = TextEditingController();
  String fLabel = 'Any';

  void assignLabels(BuildContext context, GMember m) {
    if (g.labels.isEmpty) {
      toast('Add labels in the Squad sheet tab first');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          backgroundColor: kCard,
          title: Text('Labels for ${m.name}'),
          content: SizedBox(
            width: 380,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in g.labels)
                FilterChip(
                  avatar: CircleAvatar(backgroundColor: l.c, radius: 6),
                  label: Text(l.name),
                  selected: m.labels.contains(l.id),
                  onSelected: (v) {
                    if (v) {
                      m.labels.add(l.id);
                    } else {
                      m.labels.remove(l.id);
                    }
                    set(() {});
                    S.update();
                  },
                ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Done'))],
        ),
      ),
    );
  }

  String perms(GMember m) {
    final l = [
      if (m.canChat || m.role == 'owner') 'Chat',
      if (m.role != 'member' && m.canAnnounce) 'Announce',
      if (m.role != 'member' && m.canManage) 'Manage members',
    ];
    return l.isEmpty ? 'Muted' : l.join(' · ');
  }

  void editPerms(BuildContext context, GMember m) {
    showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) {
          final admin = m.role == 'admin';
          return AlertDialog(
            backgroundColor: kCard,
            title: Text('Permissions: ${m.name}'),
            content: SizedBox(
              width: 380,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can send messages in group chat'),
                  value: m.canChat,
                  onChanged: (v) {
                    m.canChat = v;
                    set(() {});
                    S.update();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can post announcements'),
                  subtitle: admin ? null : const Text('Admins only. Promote this member first.'),
                  value: admin && m.canAnnounce,
                  onChanged: admin
                      ? (v) {
                          m.canAnnounce = v;
                          set(() {});
                          S.update();
                        }
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can add / remove members'),
                  subtitle: admin ? null : const Text('Admins only. Promote this member first.'),
                  value: admin && m.canManage,
                  onChanged: admin
                      ? (v) {
                          m.canManage = v;
                          set(() {});
                          S.update();
                        }
                      : null,
                ),
              ]),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Done'))],
          );
        },
      ),
    );
  }

  void addMember(BuildContext context) {
    final candidates = kPlayers.where((p) => g.memberOf(p) == null).take(24).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
          child: ListView(shrinkWrap: true, children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Add a member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (candidates.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Everyone is already in this group.')),
            for (final p in candidates)
              ListTile(
                leading: Avatar(p.avatar, status: p.status),
                title: Text(p.tag),
                subtitle: Text(p.games.first, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  if (g.isFull) {
                    Navigator.pop(c);
                    toast('${g.name} is full. Raise the member limit first.');
                    return;
                  }
                  g.members.add(GMember(p));
                  S.update();
                  Navigator.pop(c);
                  toast('${p.tag} added to ${g.name}');
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget menu(BuildContext context, GMember m) {
    final owner = gIsOwner(g);
    final self = identical(m.who, S.me);
    final items = <PopupMenuEntry<String>>[
      if (gCanManage(g) && m.role != 'owner') ...[
        const PopupMenuItem(value: 'labels', child: Text('Assign labels')),
        PopupMenuItem(value: 'mute', child: Text(m.canChat ? 'Mute in chat' : 'Unmute')),
      ],
      if (owner && g.isCommunity && m.role == 'member') PopupMenuItem(value: 'mod', child: Text(m.mod ? 'Remove moderator' : 'Make moderator')),
      if (!self && m.role != 'owner' && g.isCommunity && (owner || (gCanManage(g) && m.role == 'member'))) const PopupMenuItem(value: 'ban', child: Text('Ban from community')),
      if (owner && m.role != 'owner') ...[
        const PopupMenuItem(value: 'perms', child: Text('Edit permissions')),
        PopupMenuItem(value: 'role', child: Text(m.role == 'admin' ? 'Demote to member' : 'Promote to admin')),
      ],
      if (!self && m.role != 'owner' && (owner || (gCanManage(g) && m.role == 'member'))) const PopupMenuItem(value: 'remove', child: Text('Remove from group')),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Member options',
      itemBuilder: (_) => items,
      onSelected: (v) {
        if (v == 'labels') {
          assignLabels(context, m);
        } else if (v == 'mute') {
          m.canChat = !m.canChat;
          S.update();
          toast(m.canChat ? '${m.name} was unmuted' : '${m.name} was muted');
        } else if (v == 'mod') {
          m.mod = !m.mod;
          S.update();
        } else if (v == 'ban') {
          g.members.remove(m);
          g.banned.add(m.who);
          S.update();
          toast('${m.name} was banned');
        } else if (v == 'perms') {
          editPerms(context, m);
        } else if (v == 'role') {
          final up = m.role == 'member';
          m.role = up ? 'admin' : 'member';
          m.canAnnounce = up;
          m.canManage = up;
          S.update();
        } else if (v == 'remove') {
          g.members.remove(m);
          S.update();
          toast('${m.name} was removed');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = gIsMember(g);
    if (!member && !g.canView('Members')) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: lockedRow('The owner has hidden the member list from non-members')));
    }
    final canManage = gCanManage(g);
    const order = {'owner': 0, 'admin': 1, 'member': 2};
    final needle = q.text.trim().toLowerCase();
    final sorted = [
      for (final m in g.members)
        if ((needle.isEmpty || m.name.toLowerCase().contains(needle)) && (fLabel == 'Any' || m.labels.any((id) => labelOf(g, id)?.name == fLabel))) m,
    ]..sort((a, b) => order[a.role]!.compareTo(order[b.role]!));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: () => addMember(context), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add member'))),
            ),
          if (canManage && g.requests.isNotEmpty)
            Sec(
              'Join requests (${g.requests.length})',
              Column(children: [
                for (final r in List.of(g.requests))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: whoAvatar(r, radius: 20),
                    title: Text(whoName(r)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Decline', onPressed: () => S.approve(g, r, false), icon: const Icon(Icons.close, color: Colors.redAccent)),
                      IconButton(tooltip: 'Approve', onPressed: () => S.approve(g, r, true), icon: const Icon(Icons.check, color: kAccent)),
                    ]),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: q, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search members…', prefixIcon: Icon(Icons.search))),
              if (gLabelsVisible(g) && g.labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  ChoiceChip(label: const Text('All'), selected: fLabel == 'Any', onSelected: (_) => setState(() => fLabel = 'Any')),
                  for (final l in g.labels) ChoiceChip(label: Text(l.name), selected: fLabel == l.name, onSelected: (_) => setState(() => fLabel = l.name)),
                ]),
              ],
            ]),
          ),
          Sec(
            'Members (${sorted.length}${sorted.length == g.members.length ? '' : ' of ${g.members.length}'})',
            Column(children: [
              for (final m in sorted)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: whoAvatar(m.who, radius: 20),
                  title: Text('${m.name}${identical(m.who, S.me) ? ' (you)' : ''}'),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (gLabelsVisible(g) && m.labels.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: labelTags(g, m)),
                    Text(perms(m), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    infoChip(m.role == 'owner' ? 'Owner' : (m.role == 'admin' ? 'Admin' : (m.mod ? 'Moderator' : 'Member')), icon: m.role == 'member' ? null : Icons.shield_outlined, color: m.role == 'member' ? null : kAccent),
                    menu(context, m),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class GameMultiPick extends StatefulWidget {
  final List<String> selected;
  final VoidCallback onChanged;
  const GameMultiPick({super.key, required this.selected, required this.onChanged});
  @override
  State<GameMultiPick> createState() => _GameMultiPickState();
}

class _GameMultiPickState extends State<GameMultiPick> {
  final c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final q = c.text.toLowerCase();
    final m = kSorted.where((x) => x.toLowerCase().contains(q)).toList();
    final sel = widget.selected;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: c, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search games…', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 8),
      Material(
        color: kField,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: m.length,
            itemBuilder: (_, i) {
              final x = m[i];
              return ListTile(
                dense: true,
                leading: gameThumb(x, w: 42, h: 28),
                title: Text(x),
                subtitle: kUpcoming.containsKey(x) ? Text('Upcoming · ${kUpcoming[x]}', style: const TextStyle(color: Colors.amber, fontSize: 11)) : null,
                trailing: sel.contains(x) ? const Icon(Icons.check_circle, color: kAccent) : const Icon(Icons.add_circle_outline),
                onTap: () {
                  sel.contains(x) ? sel.remove(x) : sel.add(x);
                  widget.onChanged();
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
      if (sel.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final x in sel)
            InputChip(
              avatar: gameThumb(x, w: 22, h: 22),
              label: Text(x),
              onDeleted: () {
                sel.remove(x);
                widget.onChanged();
                setState(() {});
              },
            ),
        ]),
      ],
    ]);
  }
}

class CreateGroupScreen extends StatefulWidget {
  final bool community;
  const CreateGroupScreen({super.key, this.community = false});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), desc = TextEditingController();
  bool isPublic = true;
  final games = <String>[];
  String plat = 'Any', region = 'Any';
  final show = <String, bool>{'Description': true, 'Games': true, 'Members': true, 'Announcements': true, 'Labels': true, 'Squad sheet': true};
  final limit = TextEditingController(), rules = TextEditingController();
  String template = 'Start blank';

  @override
  void initState() {
    super.initState();
    if (widget.community) show.addAll({'Rules': true, 'Events': true});
  }

  void create() {
    if (!form.currentState!.validate()) return;
    if (games.isEmpty) {
      toast('Pick at least one game for your ${widget.community ? 'community' : 'group'}');
      return;
    }
    final g = S.createGroup(name.text.trim(), desc.text.trim(), isPublic, List.of(games), plat, region, show,
        community: widget.community, max: int.tryParse(limit.text.trim()), template: template, rules: rules.text.trim());
    toast(widget.community ? 'Community created' : 'Group created');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GroupScreen(g)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.community ? 'Create community' : 'Create group'), bottom: const PreferredSize(preferredSize: Size.fromHeight(3), child: GradientBar())),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  tf(name, widget.community ? 'Community name' : 'Group name', icon: widget.community ? Icons.diversity_3 : Icons.groups_outlined, max: 40, v: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null),
                  tf(desc, 'Description', lines: 3, max: 200),
                  const Text('Visibility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Public'), icon: Icon(Icons.public)),
                      ButtonSegment(value: false, label: Text('Private'), icon: Icon(Icons.lock_outline)),
                    ],
                    selected: {isPublic},
                    onSelectionChanged: (s) => setState(() => isPublic = s.first),
                  ),
                  const SizedBox(height: 6),
                  Text(isPublic ? 'Anyone can find and join this group.' : 'People request to join and you approve them.', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  const SizedBox(height: 20),
                  const Text('Games (one or more)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GameMultiPick(selected: games, onChanged: () => setState(() {})),
                  const SizedBox(height: 20),
                  PickField(label: 'Platform', value: plat, options: const ['Any', ...kPlatforms], onChanged: (v) => setState(() => plat = v)),
                  const SizedBox(height: 14),
                  PickField(label: 'Region', value: region, options: const ['Any', ...kRegions], onChanged: (v) => setState(() => region = v)),
                  const SizedBox(height: 20),
                  tf(limit, 'Member limit (leave empty for no limit)', type: TextInputType.number, v: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    return n == null || n < 2 ? 'Enter a number of 2 or more' : null;
                  }),
                  PickField(label: 'Member labels (positions or roles)', value: template, options: kLabelTemplates.keys.toList(), onChanged: (v) => setState(() => template = v)),
                  const SizedBox(height: 6),
                  const Text('You can add, rename and assign labels any time after creating.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  if (widget.community) tf(rules, 'Community rules (members accept these before chatting)', lines: 4, max: 600),
                  const Text('What non-members can see', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  for (final k in show.keys.toList())
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(k), value: show[k]!, onChanged: (v) => setState(() => show[k] = v)),
                  const SizedBox(height: 16),
                  FilledButton.icon(style: bigBtn(), onPressed: create, icon: const Icon(Icons.check), label: Text(widget.community ? 'Create community' : 'Create group')),
                ]),
              ),
            ),
          ),
        ),
      );
}

// ───────────────────────── Chats ─────────────────────────
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              pageTitle('Chats'),
              if (S.chats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No conversations yet. Invite players from Find Team to start chatting.', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                ),
              for (final c in S.chats)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: kCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Avatar(c.p.avatar, status: c.p.status),
                    title: Text(c.p.tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.msgs.isEmpty ? 'Say hi!' : c.msgs.last.text,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.normal)),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(c.msgs.isEmpty ? '' : fmtTime(c.msgs.last.t), style: TextStyle(fontSize: 12, color: c.unread > 0 ? kAccent : kMuted)),
                      const SizedBox(height: 2),
                      if (c.unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text('${c.unread}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      else
                        Text(c.p.status, style: TextStyle(fontSize: 12, color: statusColor(c.p.status))),
                    ]),
                    onTap: () => openChat(context, c),
                  ),
                ),
            ]),
          ),
        ),
      );
}

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen(this.chat, {super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final c = TextEditingController();
  final sc = ScrollController();

  @override
  void initState() {
    super.initState();
    S.activeChat = widget.chat;
    widget.chat.unread = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => S.touch());
  }

  @override
  void dispose() {
    if (identical(S.activeChat, widget.chat)) S.activeChat = null;
    super.dispose();
  }

  void send() {
    final t = c.text.trim();
    if (t.isEmpty) return;
    c.clear();
    S.send(widget.chat, t);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.chat.p;
    return ListenableBuilder(
      listenable: S,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (sc.hasClients) sc.jumpTo(sc.position.maxScrollExtent);
        });
        final msgs = widget.chat.msgs;
        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => openPlayer(context, p),
              child: Row(children: [
                Avatar(p.avatar, status: p.status, radius: 16),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.tag, style: const TextStyle(fontSize: 16)),
                  Text(p.status, style: TextStyle(fontSize: 12, color: statusColor(p.status))),
                ]),
              ]),
            ),
            actions: [PlayerMenu(p, chat: widget.chat)],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(children: [
                Expanded(
                  child: msgs.isEmpty
                      ? Center(child: Text('Say hi to ${p.tag} 👋', style: const TextStyle(color: kMuted)))
                      : ListView.builder(
                          controller: sc,
                          padding: const EdgeInsets.all(16),
                          itemCount: msgs.length,
                          itemBuilder: (_, i) {
                            final m = msgs[i];
                            final av = m.mine ? meAvatar(radius: 14) : Avatar(p.avatar, radius: 14);
                            final bubble = Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: const BoxConstraints(maxWidth: 320),
                                decoration: BoxDecoration(color: m.mine ? kAccent : kField, borderRadius: BorderRadius.circular(16)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                                  Text(m.text, style: TextStyle(color: m.mine ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                                  Text(fmtTime(m.t), style: TextStyle(fontSize: 10, color: m.mine ? Colors.white70 : kMuted)),
                                ]),
                              ),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: m.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: m.mine ? [bubble, const SizedBox(width: 8), av] : [av, const SizedBox(width: 8), bubble],
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Expanded(child: TextField(controller: c, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Message…'))),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: send, icon: const Icon(Icons.send)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
