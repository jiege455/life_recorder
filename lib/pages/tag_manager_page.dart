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
  void initState() { super.initState(); _loadTags(); }
  void _loadTags() { setState(() { _tags = _tagService.customTags; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('自定义标签', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Theme.of(context).colorScheme.primary, elevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: Column(children: [_buildAddTagSection(), Expanded(child: _buildTagsList())]),
    );
  }

  Widget _buildAddTagSection() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final primaryColor = theme.colorScheme.primary;
    return Container(padding: EdgeInsets.all(16), color: cardColor, child: Row(children: [Expanded(child: TextField(controller: _controller, style: TextStyle(color: theme.colorScheme.onSurface), decoration: InputDecoration(hintText: '输入新标签', hintStyle: TextStyle(color: subtitleColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: subtitleColor.withOpacity(0.3))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: subtitleColor.withOpacity(0.3))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))), SizedBox(width: 12), ElevatedButton(onPressed: _addTag, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)), child: Text('添加', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]));
  }

  void _addTag() async {
    final tag = _controller.text.trim();
    if (tag.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请输入标签'), backgroundColor: Colors.orange)); return; }
    if (_tags.contains(tag)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('标签已存在'), backgroundColor: Colors.orange)); return; }
    await _tagService.addTag(tag); _controller.clear(); _loadTags();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('标签已添加'), backgroundColor: Colors.green));
  }

  Widget _buildTagsList() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final primaryColor = theme.colorScheme.primary;
    if (_tags.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.label_off, size: 64, color: subtitleColor.withOpacity(0.5)), SizedBox(height: 16), Text('暂无自定义标签', style: TextStyle(fontSize: 16, color: subtitleColor)), SizedBox(height: 8), Text('添加常用标签方便快速选择', style: TextStyle(fontSize: 14, color: subtitleColor.withOpacity(0.8)))]));
    return ListView.builder(padding: EdgeInsets.all(16), itemCount: _tags.length, itemBuilder: (context, index) {
      final tag = _tags[index];
      return Container(margin: EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))]), child: ListTile(leading: Icon(Icons.label, color: primaryColor), title: Text(tag, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.edit, color: subtitleColor, size: 20), onPressed: () => _showEditDialog(tag)), IconButton(icon: Icon(Icons.delete, color: Colors.red[400], size: 20), onPressed: () => _showDeleteDialog(tag))]))));
    });
  }

  void _showEditDialog(String oldTag) {
    final editController = TextEditingController(text: oldTag);
    final theme = Theme.of(context);
    showDialog(context: context, builder: (context) => AlertDialog(title: Text('编辑标签'), backgroundColor: theme.colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), content: TextField(controller: editController, autofocus: true, decoration: InputDecoration(hintText: '输入新标签名', hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')), ElevatedButton(onPressed: () async { final newTag = editController.text.trim(); if (newTag.isNotEmpty && newTag != oldTag) { await _tagService.updateTag(oldTag, newTag); _loadTags(); } if (mounted) Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A90E2)), child: Text('保存', style: TextStyle(color: Colors.white)))]));
  }

  void _showDeleteDialog(String tag) {
    final theme = Theme.of(context);
    showDialog(context: context, builder: (context) => AlertDialog(title: Text('删除标签'), backgroundColor: theme.colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), content: Text('确定要删除标签 "$tag" 吗？'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')), ElevatedButton(onPressed: () async { await _tagService.removeTag(tag); _loadTags(); if (mounted) Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text('删除', style: TextStyle(color: Colors.white)))]));
  }
}
