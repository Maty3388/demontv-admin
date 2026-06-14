import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _State();
}

class _State extends State<DashboardScreen> {
  Map? _stats;
  List _clients = [];
  int _total = 0;
  bool _loading = true;
  String _filter = 'todos';
  String _search = '';
  final _searchCtrl = TextEditingController();
  bool _filterOpen = false;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats   = await AdminApi.getStats();
      final clients = await AdminApi.getClients(filter: _filter == 'todos' ? null : _filter, search: _search.isEmpty ? null : _search);
      setState(() { _stats = stats; _clients = clients['clients'] ?? []; _total = clients['count'] ?? 0; });
    } catch(_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    body: SafeArea(child: Column(children: [
      _header(),
      BalanceCard(balance: _stats?['balance'] ?? 0, extras: _stats?['extras'] ?? 0),
      const SizedBox(height: 12),
      _statsChart(),
      const SizedBox(height: 12),
      _clientsHeader(),
      _toolbar(),
      if (_filterOpen) _filterMenu(),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
        : _grid()),
    ])),
    floatingActionButton: _fab(),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16,12,16,8),
    child: Row(children: [
      Container(width:44,height:44,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF7B2FFF),Color(0xFFFF6B9D),Color(0xFFFFAA00)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.all_inclusive,color:Colors.white,size:24)),
      const SizedBox(width:12),
      const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Bienvenido al Panel',style:TextStyle(color:AdminTheme.textSecondary,fontSize:13)),
        Text('FluxTv Panel',style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.bold)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _showNotify,
        child: Container(padding:const EdgeInsets.all(8),margin:const EdgeInsets.only(right:8),decoration:BoxDecoration(color:AdminTheme.surface,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.notifications_outlined,color:AdminTheme.cyan,size:20)),
      ),
      GestureDetector(
        onTap: _showProfile,
        child: Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFFD700),Color(0xFFFF8C00)]),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.verified,color:Colors.white,size:20)),
      ),
    ]),
  );

  Widget _statsChart() {
    if (_stats == null) return const SizedBox();
    final activos = (_stats!['activos'] ?? 0).toDouble();
    final vencidos = (_stats!['vencidos'] ?? 0).toDouble();
    final porVencer = (_stats!['porVencer'] ?? 0).toDouble();
    final bloqueados = (_stats!['bloqueados'] ?? 0).toDouble();
    final total = activos + vencidos + porVencer + bloqueados;
    if (total == 0) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Distribución de clientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(width: 120, height: 120, child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(value: activos, color: Colors.green, title: '', radius: 30),
              PieChartSectionData(value: vencidos, color: AdminTheme.red, title: '', radius: 30),
              PieChartSectionData(value: porVencer, color: AdminTheme.gold, title: '', radius: 30),
              PieChartSectionData(value: bloqueados, color: Colors.orange, title: '', radius: 30),
            ]))),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LegendItem('Activos', activos.toInt(), Colors.green),
            _LegendItem('Vencidos', vencidos.toInt(), AdminTheme.red),
            _LegendItem('Por vencer', porVencer.toInt(), AdminTheme.gold),
            _LegendItem('Bloqueados', bloqueados.toInt(), Colors.orange),
          ])),
        ]),
      ]),
    );
  }

  Widget _clientsHeader() => Container(
    margin: const EdgeInsets.symmetric(horizontal:16),
    padding: const EdgeInsets.symmetric(vertical:12,horizontal:16),
    decoration: BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF8B2FC9),Color(0xFFFF9500)],begin:Alignment.centerLeft,end:Alignment.centerRight),borderRadius:BorderRadius.circular(12)),
    child: const Row(children:[
      Expanded(child:Text('CLIENTES',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:15,letterSpacing:2))),
      Icon(Icons.chevron_right,color:Colors.white),
    ]),
  );

  Widget _toolbar() => Padding(
    padding: const EdgeInsets.fromLTRB(16,10,16,0),
    child: Row(children:[
      GestureDetector(
        onTap: _exportCSV,
        child: Container(width:44,height:44,decoration:BoxDecoration(color:Colors.green.withOpacity(0.15),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.download_outlined,color:Colors.green,size:22)),
      ),
      const SizedBox(width:10),
      GestureDetector(
        onTap: ()=>setState(()=>_filterOpen=!_filterOpen),
        child: Container(width:44,height:44,decoration:BoxDecoration(color:_filterOpen?const Color(0xFFFF6B35):AdminTheme.surface,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.menu,color:Colors.white)),
      ),
      const SizedBox(width:10),
      Expanded(child:Container(
        height:44,decoration:BoxDecoration(color:AdminTheme.surface,borderRadius:BorderRadius.circular(10)),
        child:TextField(
          controller:_searchCtrl,
          onChanged:(v){ _search=v; _debounce?.cancel(); _debounce=Timer(const Duration(milliseconds:500),()=>_load()); },
          style:const TextStyle(color:Colors.white,fontSize:14),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search,color:AdminTheme.textHint,size:20),hintText:'Buscar',border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none,contentPadding:EdgeInsets.symmetric(vertical:12)),
        ),
      )),
      const SizedBox(width:10),
      Container(
        height:44,padding:const EdgeInsets.symmetric(horizontal:12),
        decoration:BoxDecoration(color:AdminTheme.surface,borderRadius:BorderRadius.circular(10)),
        child:Row(children:[const Icon(Icons.person_outline,color:AdminTheme.textSecondary,size:18),const SizedBox(width:4),Text('$_total',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))]),
      ),
    ]),
  );

  Widget _filterMenu() => Container(
    margin: const EdgeInsets.fromLTRB(16,4,16,0),
    decoration: BoxDecoration(color:AdminTheme.surface,borderRadius:BorderRadius.circular(12)),
    child: Column(children:['todos','activos','vencidos','porVencer','bloqueados','demos'].map((f){
      const labels={'todos':'Todos','activos':'Activos','vencidos':'Vencidos','porVencer':'Por vencer','bloqueados':'Bloqueados','demos':'Demos'};
      return ListTile(
        title:Text(labels[f]!,style:TextStyle(color:_filter==f?AdminTheme.cyan:Colors.white,fontSize:15)),
        onTap:(){setState((){_filter=f;_filterOpen=false;});_load();},
      );
    }).toList()),
  );

  Widget _grid() {
    if(_clients.isEmpty) return const Center(child:Text('Sin clientes',style:TextStyle(color:AdminTheme.textSecondary)));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16,10,16,100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.0),
      itemCount: _clients.length,
      itemBuilder: (ctx,i) => _ClientCard(client:_clients[i],onRefresh:_load),
    );
  }

  Widget _fab() => Padding(
    padding: const EdgeInsets.only(bottom:8),
    child: FloatingActionButton(
      onPressed: _showCreate,
      backgroundColor: const Color(0xFF7B2FFF),
      child: const Icon(Icons.add,color:Colors.white,size:30),
    ),
  );

  Future<void> _exportCSV() async {
    try {
      final r = await AdminApi.getClients(filter: _filter == 'todos' ? null : _filter, search: _search.isEmpty ? null : _search);
      final clients = r['clients'] ?? [];
      final rows = ['Email,Vencimiento,Estado,Dias restantes'];
      for (final c in clients) {
        final email = c['email'] ?? '';
        final exp = (c['subscription_end'] ?? '').toString().length >= 10 ? c['subscription_end'].toString().substring(0,10) : '';
        final blocked = c['blocked'] == true ? 'Bloqueado' : (c['daysLeft'] ?? 0) < 0 ? 'Vencido' : 'Activo';
        final days = c['daysLeft'] ?? 0;
        rows.add('\$email,\$exp,\$blocked,\$days');
      }
      final csv = rows.join('\n');
      final dir = Directory.systemTemp;
      final file = File('\${dir.path}/clientes_demontv.csv');
      await file.writeAsString(csv);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exportado: \${clients.length} clientes'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: AdminTheme.red));
    }
  }

  void _showNotify() => showDialog(context:context, builder:(ctx) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool sending = false;
    return StatefulBuilder(builder:(ctx, set) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: const Text('Notificar Resellers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Título', prefixIcon: Icon(Icons.title, size: 18))),
        const SizedBox(height: 12),
        TextField(controller: msgCtrl, maxLines: 3, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Mensaje', prefixIcon: Icon(Icons.message_outlined, size: 18))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: sending ? null : () async {
          if (titleCtrl.text.isEmpty || msgCtrl.text.isEmpty) return;
          set(() => sending = true);
          await AdminApi.notifyResellers(titleCtrl.text.trim(), msgCtrl.text.trim());
          Navigator.pop(ctx);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación enviada'), backgroundColor: AdminTheme.cyan));
        }, child: sending
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('ENVIAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
      ]));
  });

  void _showProfile() => showModalBottomSheet(
    context:context,backgroundColor:AdminTheme.surface,
    shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
    builder:(_)=>_ProfileSheet(),
  );

  void _showCreate() => showDialog(context:context,builder:(_)=>_CreateDialog(onCreated:_load));
}

class _ClientCard extends StatelessWidget {
  final Map client;
  final VoidCallback onRefresh;
  const _ClientCard({required this.client,required this.onRefresh});

  Color get _dateColor {
    if(client['blocked']==true) return AdminTheme.red;
    final days=client['daysLeft']??0;
    if(days<0) return AdminTheme.red;
    if(days<=5) return AdminTheme.gold;
    return Colors.white;
  }

  @override
  Widget build(BuildContext ctx) {
    final date=(client['subscription_end']??'').toString().length>=10?(client['subscription_end']??'').toString().substring(0,10):'';
    final email=client['email']??'';
    return Container(
      padding:const EdgeInsets.all(10),
      decoration:BoxDecoration(color:AdminTheme.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:AdminTheme.border,width:0.5)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Text(date,style:TextStyle(color:_dateColor,fontSize:12,fontWeight:FontWeight.w600)),
          const Spacer(),
          Container(width:32,height:32,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF1A3A6B),Color(0xFF2A5CB8)]),borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.remove_red_eye_outlined,color:Colors.white70,size:16)),
        ]),
        const SizedBox(height:6),
        Text(email,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:12)),
        const Spacer(),
        Row(children:[
          GestureDetector(onTap:()=>showDialog(context:ctx,builder:(_)=>_EditDialog(client:client,onDone:onRefresh)),child:const Icon(Icons.edit_outlined,color:AdminTheme.textSecondary,size:20)),
          const SizedBox(width:8),
          Container(width:1,height:16,color:AdminTheme.border),
          const SizedBox(width:8),
          GestureDetector(onTap:()=>showDialog(context:ctx,builder:(_)=>_ExtendDialog(client:client,onDone:onRefresh)),child:const Icon(Icons.calendar_month_outlined,color:AdminTheme.textSecondary,size:20)),
          const SizedBox(width:8),
          Container(width:1,height:16,color:AdminTheme.border),
          const SizedBox(width:8),
          GestureDetector(
            onTap:()=>showDialog(context:ctx,builder:(c)=>AlertDialog(
              backgroundColor:AdminTheme.surface,
              title:const Text('Eliminar cliente',style:TextStyle(color:Colors.white)),
              content:Text('¿Eliminar ${client['email']}?',style:const TextStyle(color:AdminTheme.textSecondary)),
              actions:[
                TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar',style:TextStyle(color:AdminTheme.textSecondary))),
                TextButton(onPressed:()async{Navigator.pop(c);await AdminApi.deleteClient(client['id']??'');onRefresh();},child:const Text('Eliminar',style:TextStyle(color:AdminTheme.red,fontWeight:FontWeight.bold))),
              ])),
            child:const Icon(Icons.delete_outline,color:AdminTheme.red,size:20)),
        ]),
      ]),
    );
  }
}

class _CreateDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateDialog({required this.onCreated});
  @override State<_CreateDialog> createState()=>_CreateState();
}
class _CreateState extends State<_CreateDialog> {
  final _e=TextEditingController(),_p=TextEditingController();
  int _months=1;bool _extras=false,_loading=false;String? _error;
  Future<void> _create() async {
    if(_e.text.isEmpty||_p.text.isEmpty){setState(()=>_error='Completá los campos');return;}
    setState(()=>_loading=true);
    final r=await AdminApi.createClient(_e.text.trim(),_p.text.trim(),_months,_extras);
    setState(()=>_loading=false);
    if(r['success']==true){widget.onCreated();Navigator.pop(context);}
    else setState(()=>_error=r['error']??'Error');
  }
  @override
  Widget build(BuildContext ctx)=>AlertDialog(
    backgroundColor:AdminTheme.surface,
    title:const Text('Crear cliente',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:_e,keyboardType:TextInputType.emailAddress,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'Correo')),
      const SizedBox(height:12),
      TextField(controller:_p,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'Contraseña')),
      const SizedBox(height:16),
      _radio('1 MES',1),_radio('2 MES',2),_radio('3 MES',3),
      const SizedBox(height:12),
      _toggle(),
      if(_error!=null)...[const SizedBox(height:8),Text(_error!,style:const TextStyle(color:AdminTheme.red,fontSize:12))],
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('CANCELAR',style:TextStyle(color:AdminTheme.textSecondary))),
      TextButton(onPressed:_loading?null:_create,child:_loading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:AdminTheme.cyan)):const Text('CREAR',style:TextStyle(color:AdminTheme.cyan,fontWeight:FontWeight.bold))),
    ],
  );
  Widget _radio(String l,int v)=>GestureDetector(onTap:()=>setState(()=>_months=v),child:Row(children:[Radio<int>(value:v,groupValue:_months,onChanged:(x)=>setState(()=>_months=x!),activeColor:AdminTheme.cyan),Text(l,style:const TextStyle(color:Colors.white))]));
  Widget _toggle()=>GestureDetector(onTap:()=>setState(()=>_extras=!_extras),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(border:Border.all(color:AdminTheme.cyan),borderRadius:BorderRadius.circular(10)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('creditos',style:TextStyle(color:_extras?AdminTheme.textSecondary:AdminTheme.cyan,fontSize:13)),Switch(value:_extras,onChanged:(v)=>setState(()=>_extras=v),activeColor:AdminTheme.cyan),Text('extras',style:TextStyle(color:_extras?AdminTheme.cyan:AdminTheme.textSecondary,fontSize:13))])));
}

class _EditDialog extends StatefulWidget {
  final Map client;final VoidCallback onDone;
  const _EditDialog({required this.client,required this.onDone});
  @override State<_EditDialog> createState()=>_EditState();
}
class _EditState extends State<_EditDialog> {
  bool _block=false,_delete=false,_pass=false;
  final _pc=TextEditingController();bool _loading=false;
  Future<void> _apply() async {
    setState(()=>_loading=true);
    if(_delete) await AdminApi.deleteClient(widget.client['id']);
    else await AdminApi.editClient(widget.client['id'],blocked:_block?true:null,password:_pass&&_pc.text.isNotEmpty?_pc.text:null);
    setState(()=>_loading=false);
    widget.onDone();Navigator.pop(context);
  }
  @override
  Widget build(BuildContext ctx)=>AlertDialog(
    backgroundColor:AdminTheme.surface,
    title:const Text('Editar cuenta',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
    content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(widget.client['email']??'',style:const TextStyle(color:AdminTheme.textSecondary,fontSize:14)),
      const SizedBox(height:16),
      _check('Bloquear',_block,(v)=>setState(()=>_block=v)),
      _check('Eliminar',_delete,(v)=>setState(()=>_delete=v)),
      _check('Contraseña',_pass,(v)=>setState(()=>_pass=v)),
      if(_pass)...[const SizedBox(height:8),TextField(controller:_pc,style:const TextStyle(color:Colors.white,fontSize:13),decoration:const InputDecoration(hintText:'Nueva contraseña'))],
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('CANCELAR',style:TextStyle(color:AdminTheme.cyan))),
      if(_block||_delete||_pass) TextButton(onPressed:_loading?null:_apply,child:Text(_delete?'ELIMINAR':'APLICAR',style:TextStyle(color:_delete?AdminTheme.red:AdminTheme.cyan,fontWeight:FontWeight.bold))),
    ],
  );
  Widget _check(String l,bool v,ValueChanged<bool> c)=>GestureDetector(onTap:()=>c(!v),child:Row(children:[Checkbox(value:v,onChanged:(x)=>c(x!),activeColor:AdminTheme.cyan,side:const BorderSide(color:AdminTheme.border,width:1.5)),Text(l,style:const TextStyle(color:Colors.white,fontSize:14))]));
}

class _ExtendDialog extends StatefulWidget {
  final Map client;final VoidCallback onDone;
  const _ExtendDialog({required this.client,required this.onDone});
  @override State<_ExtendDialog> createState()=>_ExtendState();
}
class _ExtendState extends State<_ExtendDialog> {
  int _months=1;bool _extras=false,_loading=false;String? _error;
  Future<void> _extend() async {
    setState(()=>_loading=true);
    final r=await AdminApi.extendClient(widget.client['id'],_months,_extras);
    setState(()=>_loading=false);
    if(r['success']==true){widget.onDone();Navigator.pop(context);}
    else setState(()=>_error=r['error']??'Error');
  }
  @override
  Widget build(BuildContext ctx)=>AlertDialog(
    backgroundColor:AdminTheme.surface,
    title:const Text('Agregar mes',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      Text(widget.client['email']??'',style:const TextStyle(color:AdminTheme.textSecondary,fontSize:13)),
      const SizedBox(height:16),
      GestureDetector(onTap:()=>setState(()=>_months=1),child:Row(children:[Radio<int>(value:1,groupValue:_months,onChanged:(x)=>setState(()=>_months=x!),activeColor:AdminTheme.cyan),const Text('1 MES',style:TextStyle(color:Colors.white))])),
      GestureDetector(onTap:()=>setState(()=>_months=2),child:Row(children:[Radio<int>(value:2,groupValue:_months,onChanged:(x)=>setState(()=>_months=x!),activeColor:AdminTheme.cyan),const Text('2 MES',style:TextStyle(color:Colors.white))])),
      const SizedBox(height:12),
      GestureDetector(onTap:()=>setState(()=>_extras=!_extras),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(border:Border.all(color:AdminTheme.cyan),borderRadius:BorderRadius.circular(10)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('creditos',style:TextStyle(color:_extras?AdminTheme.textSecondary:AdminTheme.cyan,fontSize:13)),Switch(value:_extras,onChanged:(v)=>setState(()=>_extras=v),activeColor:AdminTheme.cyan),Text('extras',style:TextStyle(color:_extras?AdminTheme.cyan:AdminTheme.textSecondary,fontSize:13))]))),
      if(_error!=null)...[const SizedBox(height:8),Text(_error!,style:const TextStyle(color:AdminTheme.red,fontSize:12))],
    ]),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('CANCELAR',style:TextStyle(color:AdminTheme.textSecondary))),
      TextButton(onPressed:_loading?null:_extend,child:_loading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:AdminTheme.cyan)):const Text('CARGAR',style:TextStyle(color:AdminTheme.cyan,fontWeight:FontWeight.bold))),
    ],
  );
}

class _ProfileSheet extends StatefulWidget {
  @override State<_ProfileSheet> createState()=>_ProfileState();
}
class _ProfileState extends State<_ProfileSheet> {
  Map? _p;
  @override void initState(){super.initState();AdminApi.getProfile().then((r)=>setState(()=>_p=r));}
  @override
  Widget build(BuildContext ctx)=>Padding(
    padding:const EdgeInsets.all(24),
    child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Mi Cuenta',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:20),
      const Center(child:Icon(Icons.account_circle_outlined,color:AdminTheme.textSecondary,size:72)),
      const SizedBox(height:12),
      const Center(child:Text('Información de Cuenta',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))),
      const SizedBox(height:20),
      _field(ctx,Icons.mail_outline,'Correo electrónico',_p?['email']??'...'),
      const SizedBox(height:12),
      _field(ctx,Icons.info_outline,'ID de usuario',_p?['userId']??'...',true),
      const SizedBox(height:8),
      const Center(child:Text('💡 Toca cualquier campo para copiar',style:TextStyle(color:AdminTheme.textSecondary,fontSize:12))),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:AdminTheme.surfaceAlt,padding:const EdgeInsets.symmetric(vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),onPressed:()=>Navigator.pop(ctx),child:const Text('ACEPTAR',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,letterSpacing:1.5)))),
    ]),
  );
  Widget _field(BuildContext ctx,IconData icon,String label,String value,[bool truncate=false])=>GestureDetector(
    onTap:(){Clipboard.setData(ClipboardData(text:value));ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$label copiado'),backgroundColor:AdminTheme.cyan,duration:const Duration(seconds:2)));},
    child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),decoration:BoxDecoration(color:AdminTheme.surfaceAlt,borderRadius:BorderRadius.circular(14)),child:Row(children:[Icon(icon,color:AdminTheme.textSecondary,size:22),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:AdminTheme.textSecondary,fontSize:12)),Text(truncate&&value.length>18?'${value.substring(0,18)}...':value,style:const TextStyle(color:Colors.white,fontSize:14))])),const Icon(Icons.content_copy_outlined,color:AdminTheme.textSecondary,size:18)])),
  );
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LegendItem(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12))),
      Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    ]));
}
