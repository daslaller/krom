import 'dart:async'; import 'dart:io';
class FileWatcherService { StreamSubscription<FileSystemEvent>? _sub; final _pending=<String>{}; Timer? _debounce; void Function(Set<String>)? onExternalChange;
void watch(String? root){stop(); if(root==null)return; try{_sub=Directory(root).watch(recursive:true).listen((e){if(e.type==FileSystemEvent.delete||e.type==FileSystemEvent.modify||e.type==FileSystemEvent.move){if(e.path.contains('/.git/'))return; _pending.add(e.path); _debounce?.cancel(); _debounce=Timer(const Duration(milliseconds:300),(){final b=Set<String>.from(_pending);_pending.clear(); if(b.isNotEmpty)onExternalChange?.call(b);});}});}catch(_){}}
void stop(){_sub?.cancel();_sub=null;_debounce?.cancel();_debounce=null;_pending.clear();} void dispose()=>stop();}
