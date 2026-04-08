import 'package:flutter/material.dart';
import '../services/tag_service.dart';

class TagManagerPage extends StatefulWidget {
  const TagManagerPage({super.key});

  @override
  State<TagManagerPage> createState() => _TagManagerPageState();
}

class _TagManagerPageState extends State<TagManagerPage> {
  final TagService _tagService = TagService.instance;
  List<String> _tags = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    setState(() {
      _tags = _tagService.customTags;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('自定义标签', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildAddTagSection(),
          Expanded(child: _buildTagsList()),
        ],
      ),
    );
  }

  Widget _buildAddTagSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入新标签',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF4A90E2)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _addTag,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text('添加', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addTag() async {
    final tag = _controller.text.trim();
    if (tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入标签'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标签已存在'), backgroundColor: Colors.orange),
      );
      return;
    }
    await _tagService.addTag(tag);
    _controller.clear();
    _loadTags();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('标签已添加'), backgroundColor: Colors.green),
    );
  }

  Widget _buildTagsList() {
    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_off, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text('暂无自定义标签', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            SizedBox(height: 8),
            Text('添加常用标签方便快速选择', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: ListTile(
            leading: Icon(Icons.label, color: Color(0xFF4A90E2)),
            title: Text(tag, style: TextStyle(fontSize: 15)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[500], size: 20),
                  onPressed: () => _showEditDialog(tag),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                  onPressed: () => _showDeleteDialog(tag),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(String oldTag) {
    final editController = TextEditingController(text: oldTag);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑标签'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入新标签名',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTag = editController.text.trim();
              if (newTag.isNotEmpty && newTag != oldTag) {
                await _tagService.updateTag(oldTag, newTag);
                _loadTags();
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A90E2)),
            child: Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除标签'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('确定要删除标签 "$tag" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _tagService.removeTag(tag);
              _loadTags();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
