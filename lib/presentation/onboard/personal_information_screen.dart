import 'package:chronex/base/utils/utils.dart';
import 'package:chronex/model/user_profile.dart';
import 'package:chronex/navigation/app_router_path.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:chronex/storage/hive_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/presentation/widgets/app_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:go_router/go_router.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  final _formGlobalKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? gender;
  List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _nameController.text = "Name";
      _heightController.text = "120";
      _weightController.text = "120";
      _ageController.text = "120";
      gender = "Male";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColor.primary,
      body: Center(
        child: Container(
          margin: EdgeInsets.all(24.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(16)),
          child: Form(
            key: _formGlobalKey,
            child: Column(
              spacing: 12.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildProfileWidget(),
                Text('Personal Information', style: STextTheme.text22.copyWith(fontWeight: FontWeight.w400)),
                LabelInputGroupWidget(
                  keyboardType: TextInputType.name,
                  label: "Name",
                  hintText: "Enter your name",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                LabelInputGroupWidget(
                  keyboardType: TextInputType.number,
                  label: "Height",
                  hintText: "Enter your height",
                  controller: _heightController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Height is required';
                    }
                    return null;
                  },
                ),
                LabelInputGroupWidget(
                  label: "Weight",
                  hintText: "Enter your weight",
                  controller: _weightController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Weight is required';
                    }
                    return null;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: LabelInputGroupWidget(controller: _ageController, label: "Age", hintText: "Enter your age"),
                    ),
                    12.sBWw,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gender', style: STextTheme.text14),
                          5.sBHh,
                          AppDropdown(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Gender is required';
                              }
                              return null;
                            },
                            items: buildDropdownMenuItems(genderOptions),
                            onChanged: (value) {
                              setState(() {
                                gender = value?.trim();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                2.sBHh,
                AppButton(
                  onPressed: () async {
                    if (!_formGlobalKey.currentState!.validate()) return;

                    await HiveManager('profileBox').write(
                      'user',
                      UserProfile(
                        name: _nameController.text.trim(),
                        age: int.parse(_ageController.text.trim()),
                        height: double.parse(_heightController.text.trim()),
                        weight: double.parse(_weightController.text.trim()),
                        gender: gender!,
                      ),
                    );
                    showSnackBar("Profile saved successfully");
                    if (context.mounted) {
                      context.go(AppRouterPath.home);
                    }
                  },
                  title: 'Continue',
                  width: double.infinity,
                  // borderRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Center buildProfileWidget({Color bgColor = AppColor.primary}) {
  return Center(
    child: Container(
      width: 90.w,
      height: 90.h,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(50)),
      child: Icon(CupertinoIcons.person, color: AppColor.white, size: 50.sp),
    ),
  );
}
