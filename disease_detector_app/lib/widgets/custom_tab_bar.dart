import 'package:flutter/material.dart';
import 'package:disease_detector_app/config/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar(
      {super.key, required TabController tabController, required this.tabTexts})
      : _tabController = tabController;

  final TabController _tabController;
  final List<String> tabTexts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultBorderRaduis * 2),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultBorderRaduis * 2),
          color: Theme.of(context).colorScheme.surface,
        ),
        labelStyle: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
        tabs: [
          ...tabTexts.map((text) => Tab(
                text: text,
              ))
        ],
      ),
    );
  }
}
