import 'package:flutter/material.dart';
import '../../models/place.dart';

class NewPlanModal extends StatefulWidget {
  final Function(Place)? onPersonalMemoCreated;
  final int selectedDay;

  const NewPlanModal({
    Key? key,
    this.onPersonalMemoCreated,
    required this.selectedDay,
  }) : super(key: key);

  @override
  State<NewPlanModal> createState() => _NewPlanModalState();
}

class _NewPlanModalState extends State<NewPlanModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String _selectedCategory = 'tourism';
  final List<String> _categories = ['tourism', 'restaurant', 'accommodation', 'shopping', 'other'];

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '새 여행 추가하기',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildOptionButton(
            icon: Icons.bookmark_outline,
            title: 'Bring From Saved',
            onPressed: () {
              // 기능은 아직 구현하지 않음
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('이 기능은 아직 준비 중입니다.')),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildOptionButton(
            icon: Icons.map_outlined,
            title: 'Search in Map',
            onPressed: () {
              // 기능은 아직 구현하지 않음
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('이 기능은 아직 준비 중입니다.')),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildOptionButton(
            icon: Icons.note_alt_outlined,
            title: 'Personal Memo',
            onPressed: () {
              _showPersonalMemoDialog(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(icon, size: 28),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 18),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  void _showPersonalMemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('장소 메모 입력'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '장소 이름',
                    hintText: '장소 이름을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _memoController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: '장소 설명',
                    hintText: '설명을 입력하세요...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text('카테고리', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isNotEmpty && 
                    _memoController.text.trim().isNotEmpty) {
                  if (widget.onPersonalMemoCreated != null) {
                    // Place 객체 생성
                    final Place newPlace = Place(
                      name: _titleController.text.trim(),
                      description: _memoController.text.trim(),
                      imageUrl: 'https://via.placeholder.com/150',  // 기본 이미지 URL
                      category: _selectedCategory,
                      date: '${widget.selectedDay}일차',
                    );
                    
                    widget.onPersonalMemoCreated!(newPlace);
                  }
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 모달 닫기
                  
                  // 메모가 추가되었다는 알림 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('장소가 추가되었습니다.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('장소 이름과 설명을 모두 입력해주세요.')),
                  );
                }
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }
}

// 사용 예시:
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('여행 계획')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => NewPlanModal(
              onPersonalMemoCreated: (place) {
                print('생성된 장소: ${place.name}');
                // 여기서 Place 객체를 저장하거나 처리하는 로직을 구현할 수 있습니다.
              },
              selectedDay: 1,
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Center(
        child: Text('+ 버튼을 눌러 새 여행 추가하기'),
      ),
    );
  }
}