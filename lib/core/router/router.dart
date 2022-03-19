import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/views/attach_file_view.dart';
import 'package:gsot_timekeeping/ui/views/change_password_view.dart';
import 'package:gsot_timekeeping/ui/views/chats/chat_option_view.dart';
import 'package:gsot_timekeeping/ui/views/chats/chat_room_view.dart';
import 'package:gsot_timekeeping/ui/views/chats/chats_view.dart';
import 'package:gsot_timekeeping/ui/views/chats/manage_member_view.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/views/choose_company_view.dart';
import 'package:gsot_timekeeping/ui/views/clock_in_out_register_view.dart';
import 'package:gsot_timekeeping/ui/views/coming_soon_view.dart';
import 'package:gsot_timekeeping/ui/views/compensation_register_view.dart';
import 'package:gsot_timekeeping/ui/views/contact_view.dart';
import 'package:gsot_timekeeping/ui/views/dashboard_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_company_info_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_department_manager_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_employee_ower_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_location_owner.dart';
import 'package:gsot_timekeeping/ui/views/edit_profile_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_role_manager_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_role_type_view.dart';
import 'package:gsot_timekeeping/ui/views/edit_timedefine_view.dart';
import 'package:gsot_timekeeping/ui/views/latching_work_data_view.dart';
import 'package:gsot_timekeeping/ui/views/link_social_account_view.dart';
import 'package:gsot_timekeeping/ui/views/login_view.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/views/manage_employee_view.dart';
import 'package:gsot_timekeeping/ui/views/manage_view.dart';
import 'package:gsot_timekeeping/ui/views/map_location_owner.dart';
import 'package:gsot_timekeeping/ui/views/map_tracking_view.dart';
import 'package:gsot_timekeeping/ui/views/map_view.dart';
import 'package:gsot_timekeeping/ui/views/menu_owner_view.dart';
import 'package:gsot_timekeeping/ui/views/news/list_images_page.dart';
import 'package:gsot_timekeeping/ui/views/news/news_view.dart';
import 'package:gsot_timekeeping/ui/views/nfc_scan_view.dart';
import 'package:gsot_timekeeping/ui/views/onboarding_view.dart';
import 'package:gsot_timekeeping/ui/views/overtime_register_view.dart';
import 'package:gsot_timekeeping/ui/views/profile_view.dart';
import 'package:gsot_timekeeping/ui/views/qrcode_scan_view.dart';
import 'package:gsot_timekeeping/ui/views/request_data_owner_view.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/views/salary_view.dart';
import 'package:gsot_timekeeping/ui/views/setting_authorization_view.dart';
import 'package:gsot_timekeeping/ui/views/show_map_view.dart';
import 'package:gsot_timekeeping/ui/views/supported_register_view.dart';
import 'package:gsot_timekeeping/ui/views/time_keeping_data_detail_view.dart';
import 'package:gsot_timekeeping/ui/views/time_keeping_data_view.dart';
import 'package:gsot_timekeeping/ui/views/time_keeping_success_view.dart';
import 'package:gsot_timekeeping/ui/views/time_off_view.dart';
import 'package:gsot_timekeeping/ui/views/tracking_view.dart';
import 'package:gsot_timekeeping/ui/views/user_guide_question_view.dart';
import 'package:gsot_timekeeping/ui/views/webview_view.dart';
import 'package:gsot_timekeeping/ui/views/work_outside_register_view.dart';

import '../../ui/views/time_keeping_view_new.dart';

class Routers {
  static const String main = '/';
  static const String onBoarding = 'onBoarding';
  static const String chooseCompany = 'chooseCompany';
  static const String login = 'login';
  static const String clockInOutRegister = 'clockInOutRegister';
  static const String timeOff = 'timeOff';
  static const String timeKeeping = 'timeKeeping';
  static const String dashBoard = 'dashBoard';
  static const String profile = 'profile';
  static const String editProfile = 'editProfile';
  static const String compensationRegister = 'compensationRegister';
  static const String changePassword = 'changePassword';
  static const String timeKeepingData = 'timeKeepingData';
  static const String requestData = 'requestData';
  static const String requestDataDetail = 'requestDataDetail';
  static const String workOutsideRegister = 'workOutsideRegister';
  static const String map = 'map';
  static const String latchingWork = 'latchingWork';
  static const String checkLocation = 'checkLocation';
  static const String timeKeepingSuccess = 'timeKeepingSuccess';
  static const String timeKeepingDataDetail = 'timeKeepingDataDetail';
  static const String showMap = 'showMap';
  static const String support = 'support';
  static const String settingsAuthorization = 'settingsAuthorization';
  static const String requestOwnerData = 'requestOwnerData';
  static const String userGuide = 'userGuide';
  static const String contact = 'contact';
  static const String socialLink = 'socialLink';
  static const String nfcScan = 'nfcScan';
  static const String editCompanyInfo = 'editCompanyInfo';
  static const String menuOwner = '';//'menuOwner'
  static const String editTimeDefineOwner = 'editTimeDefineOwner';
  static const String manageEmployee = 'manageEmployee';
  static const String editDepartmentOwner = 'editDepartmentOwner';
  static const String editRoleManager = 'editRoleManager';
  static const String editRoleType = 'editRoleType';
  static const String manage = 'manage';
  static const String editEmployeeOwner = 'editEmployeeOwner';
  static const String editLocationOwner = 'editLocationOwner';
  static const String mapLocationOwner = 'mapLocationOwner';
  static const String overtimeRegister = 'overtimeRegister';
  static const String comingSoon = 'comingSoon';
  static const String qrCodeScan = 'qrCodeScan';
  static const String attachFile = 'attachFile';
  // static const String timekeepingV2 = 'timekeepingV2';
  // static const String checkLocationV2 = 'checkLocationV2';
  static const String webView = 'webView';
  static const String salaryView = 'salaryView';
  static const String trackingView = 'trackingView';
  static const String mapTrackingView = 'mapTrackingView';
  static const String chatView = 'chatView';
  static const String chatEmpView = 'chatEmpView';
  static const String chatOptionView = 'chatOptionView';
  static const String chatManageMemberView = 'chatManageMemberView';
  static const String newsView='newsView';
  static const String listImagesView='listImagesView';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
        builder: (context) => route(settings),
        settings: RouteSettings(name: settings.name));
  }

  static route(RouteSettings settings) {
    switch (settings.name) {
      case onBoarding:
        return OnBoardingView();
      case chooseCompany:
        return ChooseCompanyView();
      case main:
        return MainView();
      case login:
        return LoginView();
      case clockInOutRegister:
        return ClockInOutRegisterView(settings.arguments);
      case timeOff:
        return TimeOffRegisterView(settings.arguments);
      case timeKeeping:
        return TimeKeepingViewNew(settings.arguments);
      case dashBoard:
        return DashBoardView(settings.arguments);
      case profile:
        return ProfileView();
      case editProfile:
        return EditProfileView(settings.arguments);
      case compensationRegister:
        return CompensationRegisterView();
      case changePassword:
        return ChangePasswordView();
      case timeKeepingData:
        return TimeKeepingDataView(settings.arguments);
      case requestData:
        return RequestDataView(settings.arguments);
      case requestDataDetail:
        return RequestDataDetailView();
      case workOutsideRegister:
        return WorkOutsideRegisterView(settings.arguments);
      case map:
        return MapView(settings.arguments);
      case latchingWork:
        return LatchingWorkDataView(settings.arguments);
      case checkLocation:
        return CheckLocation(settings.arguments);
      case timeKeepingSuccess:
        return TimeKeepingSuccessView(settings.arguments);
      case showMap:
        return ShowMapView(settings.arguments);
      case timeKeepingDataDetail:
        return TimeKeepingDataDetailView();
      case support:
        return SupportedRegisterView(settings.arguments);
      case settingsAuthorization:
        return SettingAuthorizationView(settings.arguments);
      case requestOwnerData:
        return RequestDataOwnerView(settings.arguments);
      case userGuide:
        return UserGuideView(settings.arguments);
      case contact:
        return ContactView();
      case socialLink:
        return LinkSocialAccountView();
      case nfcScan:
        return NFCScanView();
      case editCompanyInfo:
        return EditCompanyInfoView();
      case menuOwner:
        return MenuOwnerView(settings.arguments);
      case editTimeDefineOwner:
        return EditTimeDefineView(settings.arguments);
      case manageEmployee:
        return ManageEmployeeView(settings.arguments);
      case editDepartmentOwner:
        return EditDepartmentManagerView(settings.arguments);
      case editRoleManager:
        return EditRoleManagerView(settings.arguments);
      case editRoleType:
        return EditRoleTypeView(settings.arguments);
      case editEmployeeOwner:
        return EditEmployeeOwnerView(settings.arguments);
      case editLocationOwner:
        return EditLocationOwner(settings.arguments);
      case manage:
        return ManageView(settings.arguments);
      case mapLocationOwner:
        return MapLocationOwnerView(settings.arguments);
      case overtimeRegister:
        return OvertimeRegisterView();
      case qrCodeScan:
        return QRCodeScanView(settings.arguments);
      case attachFile:
        return AttachFileView(settings.arguments);
      // case timekeepingV2:
      //   return TimekeepingViewV2(settings.arguments);
      // case checkLocationV2:
      //   return CheckLocationV2(settings.arguments);
      case webView:
        return WebViewView();
      case salaryView:
        return SalaryView(settings.arguments);
      case trackingView:
        return TrackingView(settings.arguments);
      case mapTrackingView:
        return MapTrackingView(settings.arguments);
      case chatView:
        return ChatRoomView(settings.arguments);
      case chatEmpView:
        return ChatsView(settings.arguments);
      case chatOptionView:
        return ChatOptionView(settings.arguments);
        case chatManageMemberView:
        return ManageMemberView(settings.arguments);
      case newsView:
        return NewsView(settings.arguments);
      case listImagesView:
        return ListImagePage(settings.arguments);
      default:
        return ComingSoonView(settings.arguments);
    }
  }
}
