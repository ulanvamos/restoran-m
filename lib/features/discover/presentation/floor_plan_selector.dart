import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/table_model.dart';
import 'dart:math';

// ───── Models ─────

class FloorSection {
  final String id;
  final String name;
  FloorSection({required this.id, required this.name});
}

class EnvironmentalMarker {
  final String id;
  final String sectionId;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? edgeAlignment;

  EnvironmentalMarker({
    required this.id, required this.sectionId, required this.type,
    required this.x, required this.y, required this.width, required this.height, this.edgeAlignment
  });
}

class SelectableTable {
  final String id;
  final String sectionId;
  final int number;
  final int capacity;
  final String shape;
  final double x;
  final double y;
  final double width;
  final double height;
  final String type;
  final int reservationFee;
  final String status;

  SelectableTable({
    required this.id,
    required this.sectionId,
    required this.number,
    required this.capacity,
    required this.shape,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    required this.reservationFee,
    required this.status,
  });
}

// ───── State Notifier ─────

class FloorPlanSelectionState {
  final List<FloorSection> sections;
  final List<SelectableTable> tables;
  final List<EnvironmentalMarker> markers;
  final bool isLoading;

  FloorPlanSelectionState({
    this.sections = const [],
    this.tables = const [],
    this.markers = const [],
    this.isLoading = true,
  });
}

final customerFloorPlanProvider = FutureProvider.autoDispose.family<FloorPlanSelectionState, String>((ref, restaurantId) async {
  final supabase = Supabase.instance.client;

  final sectionsRes = await supabase.from('restaurant_sections').select().eq('restaurant_id', restaurantId);
  final tablesRes = await supabase.from('tables').select().eq('restaurant_id', restaurantId);
  final markersRes = await supabase.from('environmental_markers').select().eq('restaurant_id', restaurantId);

  final sections = (sectionsRes as List).map((e) => FloorSection(id: e['id'], name: e['name'])).toList();
  
  final tables = (tablesRes as List).map((e) => SelectableTable(
    id: e['id'],
    sectionId: e['section'] ?? (sections.isNotEmpty ? sections.first.id : ''),
    number: int.tryParse(e['table_number']?.toString() ?? '1') ?? 1,
    capacity: e['capacity'] ?? 2,
    shape: e['shape'] ?? 'square',
    x: (e['x_pos'] ?? 0).toDouble(),
    y: (e['y_pos'] ?? 0).toDouble(),
    width: (e['width'] ?? 0.08).toDouble(),
    height: (e['height'] ?? 0.12).toDouble(),
    type: e['type'] ?? 'table',
    reservationFee: e['reservation_fee'] ?? 0,
    status: e['status'] ?? 'empty',
  )).toList();

  final markers = (markersRes as List).map((e) => EnvironmentalMarker(
    id: e['id'],
    sectionId: e['section'],
    type: e['type'],
    x: (e['x_pos'] ?? 0).toDouble(),
    y: (e['y_pos'] ?? 0).toDouble(),
    width: (e['width'] ?? 0.15).toDouble(),
    height: (e['height'] ?? 0.03).toDouble(),
    edgeAlignment: e['edge_alignment'],
  )).toList();

  return FloorPlanSelectionState(
    sections: sections,
    tables: tables,
    markers: markers,
    isLoading: false,
  );
});

// ───── Widget ─────

class FloorPlanSelector extends ConsumerStatefulWidget {
  final String restaurantId;
  final SelectableTable? selectedTable;
  final ValueChanged<SelectableTable> onTableSelected;

  const FloorPlanSelector({
    super.key,
    required this.restaurantId,
    this.selectedTable,
    required this.onTableSelected,
  });

  @override
  ConsumerState<FloorPlanSelector> createState() => _FloorPlanSelectorState();
}

class _FloorPlanSelectorState extends ConsumerState<FloorPlanSelector> {
  String? _selectedSectionId;
  final double canvasAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(customerFloorPlanProvider(widget.restaurantId));

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
      data: (state) {
        if (state.sections.isEmpty && state.tables.isEmpty) {
          return const Center(child: Text('Kroki bulunamadı. Lütfen restorana ulaşın.', style: TextStyle(color: AppColors.textSecondary)));
        }

        _selectedSectionId ??= state.sections.isNotEmpty ? state.sections.first.id : null;

        final currentTables = state.tables.where((t) => t.sectionId == _selectedSectionId || state.sections.isEmpty).toList();
        final currentMarkers = state.markers.where((m) => m.sectionId == _selectedSectionId || state.sections.isEmpty).toList();

        return Column(
          children: [
            // Tabs
            if (state.sections.length > 1)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.sections.length,
                  itemBuilder: (ctx, i) {
                    final sec = state.sections[i];
                    final isSelected = _selectedSectionId == sec.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSectionId = sec.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.divider.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sec.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Fixed Canvas Area
            AspectRatio(
              aspectRatio: canvasAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5), width: 4),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double canvasW = constraints.maxWidth;
                      final double canvasH = constraints.maxHeight;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Markers (Windows, Doors, WC)
                          ...currentMarkers.map((m) => Positioned(
                            left: m.x * canvasW,
                            top: m.y * canvasH,
                            width: m.width * canvasW,
                            height: m.height * canvasH,
                            child: _MarkerEdgeWidget(marker: m),
                          )),

                          // Tables and Cash Registers
                          ...currentTables.map((t) {
                            final isSelected = widget.selectedTable?.id == t.id;
                            final isAvailable = t.status == 'empty';
                            return Positioned(
                              left: t.x * canvasW,
                              top: t.y * canvasH,
                              width: t.width * canvasW,
                              height: t.height * canvasH,
                              child: GestureDetector(
                                onTap: isAvailable && t.type == 'table' ? () => widget.onTableSelected(t) : null,
                                child: _CustomerTableWidget(table: t, isSelected: isSelected, isAvailable: isAvailable),
                              ),
                            );
                          }),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MarkerEdgeWidget extends StatelessWidget {
  final EnvironmentalMarker marker;
  const _MarkerEdgeWidget({required this.marker});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch(marker.type) {
      case 'window': color = Colors.lightBlue.withOpacity(0.5); icon = Icons.window; break;
      case 'entrance': color = Colors.brown.withOpacity(0.5); icon = Icons.door_front_door; break;
      case 'wc': color = Colors.orange.withOpacity(0.5); icon = Icons.wc; break;
      default: color = Colors.grey; icon = Icons.info;
    }

    return Container(
      decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black26)),
      child: Center(
        child: Icon(icon, color: Colors.black54, size: min(marker.width, marker.height) > 0.05 ? 16 : 8),
      ),
    );
  }
}

class _CustomerTableWidget extends StatelessWidget {
  final SelectableTable table;
  final bool isSelected;
  final bool isAvailable;

  const _CustomerTableWidget({required this.table, required this.isSelected, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    if (table.type == 'cash_register') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.point_of_sale, color: Colors.green, size: 16),
        ),
      );
    }

    Color borderColor = isSelected ? AppColors.primary : (isAvailable ? Colors.grey.shade400 : Colors.red.shade300);
    Color bgColor = isSelected ? AppColors.primary.withOpacity(0.1) : (isAvailable ? Colors.white : Colors.red.shade50);
    Color textColor = isSelected ? AppColors.primary : (isAvailable ? Colors.black87 : Colors.red.shade400);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: table.shape == 'round' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: table.shape == 'square' ? BorderRadius.circular(8) : null,
        border: Border.all(color: borderColor, width: isSelected ? 3 : 1.5),
        boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)] : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isSmall = constraints.maxWidth < 30 || constraints.maxHeight < 30;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${table.number}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 8 : 14, color: textColor)),
                  if (!isSmall)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 8, color: textColor.withOpacity(0.7)),
                        Text('${table.capacity}', style: TextStyle(fontSize: 8, color: textColor.withOpacity(0.7))),
                      ],
                    ),
                ],
              );
            }
          ),
          if (table.reservationFee > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.attach_money, size: 6, color: Colors.white),
              ),
            )
        ],
      ),
    );
  }
}
