import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/services/ad_service.dart';
import '../../models/guida.dart';
import 'guide_data.dart';
import 'guide_detail_screen.dart';

class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key});

  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen> {
  String _selectedCategory = 'Tutti';
  String _searchQuery = '';
  late List<Guida> _allGuide;

  @override
  void initState() {
    super.initState();
    _allGuide = GuideData.getAllGuide();
  }

  List<Guida> get _filteredGuide {
    return _allGuide.where((g) {
      final matchCat = _selectedCategory == 'Tutti' || g.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.shortDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildCategories()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('${_filteredGuide.length} guide disponibili',
                style: const TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildGuideCard(_filteredGuide[i]),
              childCount: _filteredGuide.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BannerAdWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 14),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: const Row(children: [
        Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Text('Guide Pratiche', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'Cerca una guida...',
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final cats = GuideData.getCategories();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final sel = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE0E0E0)),
              ),
              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textMedium)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideCard(Guida guida) {
    return GestureDetector(
      onTap: () {
        AdService().onNavigateToDetail();
        Navigator.push(context, MaterialPageRoute(builder: (_) => GuideDetailScreen(guida: guida)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: guida.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(guida.icon, color: guida.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(guida.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 3),
            Text(guida.shortDescription, style: const TextStyle(fontSize: 11, color: Color(0xFF888888)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.navInactive, size: 20),
        ]),
      ),
    );
  }
}
