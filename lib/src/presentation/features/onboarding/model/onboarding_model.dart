part of '../view/onboarding_page.dart';

typedef _OnboardingItem = ({
  int index,
  String title,
  Widget image,
  List<String> features,
});

List<_OnboardingItem> _getOnboardingItems(BuildContext context) => [
  (
    index: 0,
    title: context.locale.learnFlutterTitle,
    image: const FlutterLogo(size: 200),
    features: [
      context.locale.learnFlutterSubtitle,
      context.locale.learnFlutterDescription,
    ],
  ),
  (
    index: 1,
    title: context.locale.joinCommunityTitle,
    image: const FlutterLogo(size: 200),
    features: [
      context.locale.joinCommunitySubtitle,
      context.locale.joinCommunityDescription,
    ],
  ),
  (
    index: 2,
    title: context.locale.buildDeployTitle,
    image: const FlutterLogo(size: 200),
    features: [
      context.locale.buildDeploySubtitle,
      context.locale.buildDeployDescription,
    ],
  ),
];
