// Mini-Activity Enums

enum MiniActivityType {
  individual,
  team;

  String get displayName {
    switch (this) {
      case MiniActivityType.individual:
        return 'Individuell';
      case MiniActivityType.team:
        return 'Lag';
    }
  }

  static MiniActivityType fromString(String type) {
    switch (type) {
      case 'team':
        return MiniActivityType.team;
      default:
        return MiniActivityType.individual;
    }
  }

  String toApiString() => name;
}

enum DivisionMethod {
  random,
  ranked,
  age,
  gmo,
  cup,
  manual;

  String get displayName {
    switch (this) {
      case DivisionMethod.random:
        return 'Tilfeldig';
      case DivisionMethod.ranked:
        return 'Etter rating';
      case DivisionMethod.age:
        return 'Etter alder';
      case DivisionMethod.gmo:
        return 'Gamle mot unge';
      case DivisionMethod.cup:
        return 'Cup (flere lag)';
      case DivisionMethod.manual:
        return 'Manuell';
    }
  }

  String get description {
    switch (this) {
      case DivisionMethod.random:
        return 'Spillerne fordeles tilfeldig pa lagene';
      case DivisionMethod.ranked:
        return 'Spillerne fordeles etter intern rating (snake draft)';
      case DivisionMethod.age:
        return 'Spillerne fordeles etter alder';
      case DivisionMethod.gmo:
        return 'De eldste mot de yngste';
      case DivisionMethod.cup:
        return 'Rettferdig fordeling pa flere lag (snake draft)';
      case DivisionMethod.manual:
        return 'Du velger selv hvem som skal pa hvert lag';
    }
  }

  bool get supportsMultipleTeams {
    return this == DivisionMethod.cup;
  }

  static DivisionMethod fromString(String? method) {
    switch (method) {
      case 'ranked':
        return DivisionMethod.ranked;
      case 'age':
        return DivisionMethod.age;
      case 'gmo':
        return DivisionMethod.gmo;
      case 'cup':
        return DivisionMethod.cup;
      case 'manual':
        return DivisionMethod.manual;
      default:
        return DivisionMethod.random;
    }
  }

  String toApiString() => name;
}
