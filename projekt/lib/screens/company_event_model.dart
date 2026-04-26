class CompanyEvent {
  final String  id;
  final String  title;
  final String  city;
  final String? specificLocation;
  final String? eventDate;
  final String? timeStart;
  final String? timeEnd;
  final String? category;
  final String? ageGroup;
  final String? genderGroup;
  final int     attendeeCount;
  final int?    maxAttendees;
  final bool    isFull;
  final double? ticketPrice;
  final String? ticketCurrency;
  final String? cardColorHex;
  final String? description;
  final String? coverPhotoUrl;

  const CompanyEvent({
    required this.id,
    required this.title,
    required this.city,
    this.specificLocation,
    this.eventDate,
    this.timeStart,
    this.timeEnd,
    this.category,
    this.ageGroup,
    this.genderGroup,
    required this.attendeeCount,
    this.maxAttendees,
    required this.isFull,
    this.ticketPrice,
    this.ticketCurrency,
    this.cardColorHex,
    this.description,
    this.coverPhotoUrl,
  });

  factory CompanyEvent.fromJson(Map<String, dynamic> j) => CompanyEvent(
    id:               j['id'] ?? '',
    title:            j['title'] ?? '',
    city:             j['city'] ?? '',
    specificLocation: j['specificLocation'],
    eventDate:        j['eventDate'],
    timeStart:        j['timeStart'],
    timeEnd:          j['timeEnd'],
    category:         j['category'],
    ageGroup:         j['ageGroup'],
    genderGroup:      j['genderGroup'],
    attendeeCount:    j['attendeeCount'] ?? 0,
    maxAttendees:     j['maxAttendees'],
    isFull:           j['full'] ?? j['isFull'] ?? false,
    ticketPrice:      (j['ticketPrice'] as num?)?.toDouble(),
    ticketCurrency:   j['ticketCurrency'],
    cardColorHex:     j['cardColorHex'],
    description:      j['description'],
    coverPhotoUrl:    j['coverPhotoUrl'] as String?,
  );
}