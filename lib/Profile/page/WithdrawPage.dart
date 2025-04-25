import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ProfilePage.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '탈퇴하면 아래의 정보가 삭제되니 주의해 주세요!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 삭제될 항목들
                    _buildBulletItem('회원님의 활동 이력 및 설정 내역'),
                    _buildBulletItem('회원님의 개인 정보'),
                    _buildBulletItem('회원님의 북마크 내역'),
                    const SizedBox(height: 24),
                    const Text(
                      '회원 탈퇴 후 취소가 불가능합니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 체크박스 + 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('정말 계정을 영구 삭제하시겠습니까?')
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: !_agreed ? null : (){
                          _onWithdraw(Provider.of<UserDataProvider>(context, listen: false).currentUserUID!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // 활성 시 빨간색
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),

                      ),
                      child: const Text(
                        '회원 탈퇴',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _onWithdraw(String uid) async {
    final reasons = await showReasonDialog(context);
    if (reasons == null || reasons.isEmpty) return;

    final supabase = Supabase.instance.client;

    try {
      // 탈퇴 사유 저장
      await supabase.from('withdraw_logs').insert({
        'uid': uid,
        'withdraw_reasons': reasons,
      });
    } catch (e) {
      print('탈퇴 사유 저장 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 사유 저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
      return;
    }

    try {
      // Edge Function 호출하여 계정 삭제
      final response = await supabase.functions.invoke('delete_user', body: {'name': 'Functions'});

      if (response.status == 200) {
        // 계정 삭제 성공 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계정이 성공적으로 삭제되었습니다.')),
        );
        Provider.of<UserDataProvider>(context, listen: false).logout();
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
              (route) => false,
        );
      } else {
        final error = response.data['error'] ?? '알 수 없는 오류가 발생했습니다.';
        print('계정 삭제 실패: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 삭제 중 오류가 발생했습니다: $error')),
        );
      }
    } catch (e) {
      print('Edge Function 호출 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }



  Future<List<String>?> showReasonDialog(BuildContext context) {
    final reasons = [
      '서비스 이용이 불편해서',
      '이제 앱을 이용하지 않아서',
      '컨텐츠가 부족해서',
      '기타'
    ];
    final selected = List<bool>.filled(reasons.length, false);

    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          child: StatefulBuilder(
            builder: (context, setState) {
              // 버튼 활성 조건: selected 리스트 중 하나라도 true
              final isAnySelected = selected.any((e) => e);

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '탈퇴 사유 선택',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reasons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return CheckboxListTile(
                            value: selected[i],
                            onChanged: (v) => setState(() => selected[i] = v!),
                            title: Text(reasons[i]),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: Colors.blue,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        // selected 중 하나라도 true면 활성화
                        onPressed: isAnySelected
                            ? () {
                          final chosen = <String>[];
                          for (var i = 0; i < reasons.length; i++) {
                            if (selected[i]) chosen.add(reasons[i]);
                          }
                          Navigator.of(context).pop(chosen);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          '회원 탈퇴',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }



}
