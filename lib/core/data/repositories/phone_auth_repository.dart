import "package:dartz/dartz.dart";
import "package:help_out/core/data/data_sources/phone_auth_data_source.dart";
import "package:help_out/core/domain/entities/phone_verify_result.dart";
import "package:help_out/core/domain/errors/app_error.dart";

class PhoneAuthRepository {
  PhoneAuthRepository({required this._phoneAuthDataSource});

  final PhoneAuthDataSource _phoneAuthDataSource;

  Future<Either<AppError, void>> requestCode(String phoneNumber) =>
      _phoneAuthDataSource.requestCode(phoneNumber);

  Future<Either<AppError, PhoneVerifyResult>> verifyCode({
    required String phoneNumber,
    required String code,
  }) => _phoneAuthDataSource.verifyCode(phoneNumber: phoneNumber, code: code);
}
