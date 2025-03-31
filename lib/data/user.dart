class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String phoneNumber;

  AppUser({
    required this.uid,
    required this.phoneNumber,
    this.email,
    this.displayName,
    this.photoURL,
  });

  Map<String, dynamic> toMap() {
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
}
