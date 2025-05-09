class AppUser {
  final String uid; // 유저 아이디 null x
  final String email; // 유저 이메일 null x
  final String displayName; // 유저 이름 null x
  final String photoURL; // 프로필 UrL null x -  프로필 없더라도 기본 이미지 Url 넣어줌
  final String phoneNumber; // 휴대폰번호

  AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.email,
    required this.displayName,
    required this.photoURL,
  });

  Map<String, dynamic> toMap() { // 클래스를 맵으로 변환(json형식)
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      phoneNumber: map['phoneNumber'],
    );
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoURL,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}
