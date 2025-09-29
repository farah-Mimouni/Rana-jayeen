class DirectionDetailsInfo {
  String? e_point;
  String? distance_text;
  int? distance_value;
  String? duration_text;
  int? duration_value;
  DirectionDetailsInfo({
    this.distance_text,
    this.distance_value,
    this.duration_text,
    this.duration_value,
    this.e_point,
  });
  Map<String, dynamic> toJson() => {
        'e_point': e_point,
        'distance_text': distance_text,
        'distance_value': distance_value,
        'duration_text': duration_text,
        'duration_value': duration_value,
      };

  factory DirectionDetailsInfo.fromJson(Map<String, dynamic> json) =>
      DirectionDetailsInfo()
        ..e_point = json['e_point']
        ..distance_text = json['distance_text']
        ..distance_value = json['distance_value']
        ..duration_text = json['duration_text']
        ..duration_value = json['duration_value'];
}
