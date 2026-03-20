import 'package:flutter/material.dart';

import 'features/vehicles/data/hive_boxes.dart';

/// Simple AR/EN localization. No packages needed.
class S {
  static final ValueNotifier<bool> isArabic = ValueNotifier(false);

  static void init() {
    isArabic.value = HiveBoxes.metaBox().get('lang') == 'ar';
  }

  static void toggle() {
    isArabic.value = !isArabic.value;
    HiveBoxes.metaBox().put('lang', isArabic.value ? 'ar' : 'en');
  }

  static String get locale => isArabic.value ? 'ar' : 'en';

  // -- App --
  static String get maintenance => isArabic.value ? 'الصيانة' : 'Maintenance';
  static String get settings => isArabic.value ? 'الإعدادات' : 'Settings';
  static String vehicles(int n) => isArabic.value
      ? (n == 1 ? 'مركبة واحدة' : '$n مركبات')
      : (n == 1 ? '1 vehicle' : '$n vehicles');

  // -- Home --
  static String get noVehiclesYet => isArabic.value ? 'لا توجد مركبات' : 'No vehicles yet';
  static String get tapToAdd => isArabic.value ? 'اضغط + للإضافة' : 'Tap + to add one';
  static String get allOk => isArabic.value ? 'كل شيء تمام' : 'All OK';
  static String overdue(int n) => isArabic.value ? '$n متأخر' : '$n overdue';
  static String due(int n) => isArabic.value ? '$n مستحق' : '$n due';
  static String get details => isArabic.value ? 'التفاصيل' : 'Details';
  static String get edit => isArabic.value ? 'تعديل' : 'Edit';
  static String get delete => isArabic.value ? 'حذف' : 'Delete';

  // -- Vehicle form --
  static String get addVehicle => isArabic.value ? 'إضافة مركبة' : 'Add vehicle';
  static String get editVehicle => isArabic.value ? 'تعديل مركبة' : 'Edit vehicle';
  static String get vehicleName => isArabic.value ? 'اسم المركبة' : 'Vehicle name';
  static String get currentMileageKm => isArabic.value ? 'العداد الحالي (كم)' : 'Current mileage (km)';
  static String get photoOptional => isArabic.value ? 'أضف صورة (اختياري)' : 'Add a car photo (optional).';
  static String get saveVehicle => isArabic.value ? 'حفظ' : 'Save vehicle';
  static String get updateVehicle => isArabic.value ? 'تحديث' : 'Update vehicle';
  static String get enterName => isArabic.value ? 'أدخل الاسم' : 'Enter a name';
  static String get enterMileage => isArabic.value ? 'أدخل العداد' : 'Enter mileage';
  static String get enterValidNumber => isArabic.value ? 'أدخل رقم صحيح' : 'Enter a valid number';

  // -- Detail page --
  static String get checklist => isArabic.value ? 'قائمة الصيانة' : 'Checklist';
  static String get history => isArabic.value ? 'السجل' : 'History';
  static String get noItems => isArabic.value ? 'لا توجد عناصر صيانة' : 'No maintenance items.';
  static String get noHistory => isArabic.value ? 'لا يوجد سجل' : 'No history yet.';
  static String get update => isArabic.value ? 'تحديث' : 'Update';
  static String get done => isArabic.value ? 'تم' : 'Done';
  static String get skip => isArabic.value ? 'تخطي' : 'Skip';
  static String get save => isArabic.value ? 'حفظ' : 'Save';
  static String get priceEgpOptional => isArabic.value ? 'السعر (ج.م) — اختياري' : 'Price (EGP) — optional';
  static String kmLeft(int km) => isArabic.value ? '$km كم متبقي' : '$km km left';
  static String kmOverdue(int km) => isArabic.value ? '$km كم متأخر' : '$km km overdue';
  static String get statusOk => 'OK';
  static String get statusDue => isArabic.value ? 'مستحق' : 'DUE';
  static String get statusOverdue => isArabic.value ? 'متأخر' : 'OVERDUE';

  // -- Settings --
  static String get data => isArabic.value ? 'البيانات' : 'Data';
  static String get export_ => isArabic.value ? 'تصدير' : 'Export';
  static String get import_ => isArabic.value ? 'استيراد' : 'Import';
  static String get maintenanceTypes => isArabic.value ? 'أنواع الصيانة' : 'Maintenance types';
  static String get newType => isArabic.value ? 'نوع جديد' : 'New type';
  static String get name_ => isArabic.value ? 'الاسم' : 'Name';
  static String get intervalKm => isArabic.value ? 'المسافة (كم)' : 'Interval (km)';
  static String get intervalMonths => isArabic.value ? 'المدة (شهور)' : 'Interval (months)';
  static String get add => isArabic.value ? 'إضافة' : 'Add';
  static String get cancel => isArabic.value ? 'إلغاء' : 'Cancel';
  static String get language => isArabic.value ? 'اللغة' : 'Language';
  static String get noTypes => isArabic.value ? 'لا توجد أنواع' : 'No types.';

  // -- Dialogs --
  static String get deleteVehicleQ => isArabic.value ? 'حذف المركبة؟' : 'Delete vehicle?';
  static String deleteVehicleMsg(String name) =>
      isArabic.value ? 'حذف "$name"؟' : 'Delete "$name"?';
  static String get deleteTypeQ => isArabic.value ? 'حذف النوع؟' : 'Delete type?';
  static String deleteTypeMsg(String name) =>
      isArabic.value ? 'حذف "$name" من جميع المركبات؟' : 'Delete "$name" from all vehicles?';
  static String get importDataQ => isArabic.value ? 'استيراد البيانات؟' : 'Import data?';
  static String get importDataMsg =>
      isArabic.value ? 'سيتم استبدال جميع البيانات الحالية.' : 'This will replace ALL current data.';
  static String get importedOk => isArabic.value ? 'تم الاستيراد بنجاح' : 'Imported successfully';
  static String get exportedOk => isArabic.value ? 'تم التصدير' : 'Exported';

  // -- Detail page extras --
  static String get addItem => isArabic.value ? 'إضافة عنصر صيانة' : 'Add maintenance item';
  static String get pickType => isArabic.value ? 'اختر نوع الصيانة' : 'Pick a type';
  static String get customItem => isArabic.value ? 'عنصر مخصص' : 'Custom item';
  static String get removeItem => isArabic.value ? 'إزالة العنصر؟' : 'Remove item?';
  static String removeItemMsg(String name) =>
      isArabic.value ? 'إزالة "$name" من هذه المركبة؟' : 'Remove "$name" from this vehicle?';
  static String get removed => isArabic.value ? 'تم الحذف' : 'Removed';
  static String get editInterval => isArabic.value ? 'تعديل الفترة' : 'Edit interval';
  static String get deleteRecordQ => isArabic.value ? 'حذف السجل؟' : 'Delete record?';
  static String get deleteRecordMsg => isArabic.value ? 'حذف هذا السجل؟' : 'Delete this history entry?';
  static String get undo => isArabic.value ? 'تراجع' : 'Undo';
}
