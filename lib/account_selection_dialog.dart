import 'package:flutter/material.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
final Color greyText = Color(0xFF707070);

class AccountSelectionDialog extends StatelessWidget {
  final List<dynamic> accounts;
  final Function(dynamic) onSelect;

  const AccountSelectionDialog({
    super.key,
    required this.accounts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "اختر الحساب المراد الدخول به",
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 18,
            fontWeight: FontWeight.bold
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            // محاولة جلب الاسم من أكثر من مفتاح متوقع من السيرفر
            String displayName = account['fullName'] ??
                account['name'] ??
                account['userName'] ??
                account['username'] ?? "مستخدم نظام";

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(
                  displayName,
                  style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
                ),
                subtitle: Text(
                  "نوع الحساب: ${_getUserTypeName(account['userType'])}",
                  style: TextStyle(color: greyText, fontSize: 12, fontFamily: 'Almarai'),
                ),
                trailing: ElevatedButton(
                  onPressed: () => onSelect(account),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)
                    ),
                  ),
                  child: const Text(
                      "دخول",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Almarai')
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getUserTypeName(dynamic type) {
    int t = int.tryParse(type?.toString() ?? "0") ?? 0;
    switch (t) {
      case 0:
        return "مستخدم عام"; // أو حسب ما يقولك صاحبك
      case 1:
      case 4:
        return "معلم/معلمة";
      case 2:
        return "إدارة";
      case 3:
        return "محاسب";
      default:
        return "طالب";
    }
  }
}