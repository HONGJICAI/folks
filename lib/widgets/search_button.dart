import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../screens/person_search.dart';

/// 顶栏共用的全局搜索按钮：搜所有人（家族 + 圈子）。
class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: context.l10n.searchHint,
      onPressed: () => showSearch<void>(
        context: context,
        delegate: PersonSearchDelegate(
          context.read<FolksRepository>(),
          hint: context.l10n.searchHint,
        ),
      ),
    );
  }
}
