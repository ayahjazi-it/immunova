class get_all_Patient_model {
  List<Data>? data;

  get_all_Patient_model({this.data,});

  get_all_Patient_model.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  String? patientCode;
  String? name;
  String? email;
  String? phone;
  String? dateOfBirth;
  String? gender;
  String? status;
  String? medicalNotes;

  Data(
      {this.id,
      this.patientCode,
      this.name,
      this.email,
      this.phone,
      this.dateOfBirth,
      this.gender,
      this.status,
      this.medicalNotes});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    patientCode = json['patient_code'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    dateOfBirth = json['date_of_birth'];
    gender = json['gender'];
    status = json['status'];
    medicalNotes = json['medical_notes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['patient_code'] = this.patientCode;
    data['name'] = this.name;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['date_of_birth'] = this.dateOfBirth;
    data['gender'] = this.gender;
    data['status'] = this.status;
    data['medical_notes'] = this.medicalNotes;
    return data;
  }
}