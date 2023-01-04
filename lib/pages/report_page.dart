import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/widgets/list/report_list.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        children: const [
          PageTitle(
            title: 'Relatórios',
          ),
          ReportList()
        ],
      ),
    );
  }
}
