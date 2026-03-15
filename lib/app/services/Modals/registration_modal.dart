import 'package:json_annotation/json_annotation.dart';

part 'registration_modal.g.dart';
@JsonSerializable()
class RegistrationModel {
  final String businessName;
  final String brandName;
  final String email;
  final String password;
  final String businessType;
  final String address;
  final String city;
  final String state;
  final String zipcode;
  final String country;
  final String firstName;
  final String lastName;
  final String title;
  final String mobile;

  RegistrationModel({
    required this.businessName,
    required this.brandName,
    required this.email,
    required this.password,
    required this.businessType,
    required this.address,
    required this.city,
    required this.state,
    required this.zipcode,
    required this.country,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.mobile,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      businessName: json['businessName'] ?? '',
      brandName: json['brandName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      businessType: json['businessType'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipcode: json['zipcode'] ?? '',
      country: json['country'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      title: json['title'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'brandName': brandName,
      'email': email,
      'password': password,
      'businessType': businessType,
      'address': address,
      'city': city,
      'state': state,
      'zipcode': zipcode,
      'country': country,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'mobile': mobile,
    };
  }
}
