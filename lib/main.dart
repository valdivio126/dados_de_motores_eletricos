import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Login()));
}

List<Map<String, dynamic>> motores = [];
List<Map<String, dynamic>> patrocinadores = [];
List<Map<String, dynamic>> clientes = [];
String nomeClienteLogado = '';
String idClienteLogado = '';

class Login extends StatefulWidget {
  const Login({super.key});
  @override State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final senha = TextEditingController();
  final cNomeCliente = TextEditingController();
  final cFoneCliente = TextEditingController();
  final cEmailCliente = TextEditingController();
  final cSenhaCliente = TextEditingController();
  bool isAdmin = true;
  bool verSenhaAdmin = false;
  bool isCadastro = false;
  bool carregando = false;

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(child: SingleChildScrollView(child: Container(width: 460, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.electric_bolt, size: 50, color: Color(0xFF0D47A1)),
        const Text('DADOS MOTORES v40 - 10K MOTORES / 1K CLIENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)), child: const Text('ESCALÁVEL - FIREBASE + STORAGE - 10K', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('ADMIN')), ButtonSegment(value: false, label: Text('CLIENTE R\$29,90'))], selected: {isAdmin}, onSelectionChanged: (v) => setState(() {isAdmin = v.first; isCadastro=false;})),
        const SizedBox(height: 10),
        if (!isAdmin &&!isCadastro)...[
          TextField(controller: cFoneCliente, decoration: const InputDecoration(labelText: 'WHATSAPP / ID *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
          const SizedBox(height: 8),
          TextField(controller: cSenhaCliente, obscureText: true, decoration: const InputDecoration(labelText: 'SENHA *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
          const SizedBox(height: 8),
          TextButton(onPressed: ()=> setState(()=> isCadastro=true), child: const Text('Não tem conta? CADASTRE-SE')),
        ],
        if (!isAdmin && isCadastro)...[
          const Text('CADASTRO - NOME, FONE, EMAIL, SENHA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(controller: cNomeCliente, decoration: const InputDecoration(labelText: 'NOME EMPRESA *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
          const SizedBox(height: 8),
          TextField(controller: cFoneCliente, decoration: const InputDecoration(labelText: 'TELEFONE WHATSAPP * (ID)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 8),
          TextField(controller: cEmailCliente, decoration: const InputDecoration(labelText: 'EMAIL *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
          const SizedBox(height: 8),
          TextField(controller: cSenhaCliente, obscureText: true, decoration: const InputDecoration(labelText: 'CRIE SUA SENHA *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
          const SizedBox(height: 8),
          TextButton(onPressed: ()=> setState(()=> isCadastro=false), child: const Text('Já tenho conta, LOGIN')),
        ],
        if (isAdmin) TextField(controller: senha, obscureText:!verSenhaAdmin, decoration: InputDecoration(border: const OutlineInputBorder(), labelText: 'SENHA ADMIN', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(verSenhaAdmin? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => verSenhaAdmin =!verSenhaAdmin)))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: () async {
          setState(()=> carregando=true);
          final p = await SharedPreferences.getInstance();
          try { var snap = await FirebaseFirestore.instance.collection('clientes').limit(1000).get(); if(snap.docs.isNotEmpty){ clientes = snap.docs.map((d) => d.data()).toList(); await p.setString('clientes', jsonEncode(clientes)); } } catch(e){}
          if (p.getString('clientes')!= null && clientes.isEmpty) { try { clientes = List<Map<String, dynamic>>.from(jsonDecode(p.getString('clientes')!)); } catch(e){} }
          setState(()=> carregando=false);
          if (isAdmin) { if (senha.text == 'didi1507') { nomeClienteLogado = 'ADMIN'; idClienteLogado = 'ADMIN'; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home(isAdmin: true))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SENHA ADMIN ERRADA!'), backgroundColor: Colors.red)); } }
          else {
            if(isCadastro){
              if (cNomeCliente.text.trim().isEmpty || cFoneCliente.text.trim().isEmpty || cEmailCliente.text.trim().isEmpty || cSenhaCliente.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PREENCHA NOME, FONE, EMAIL, SENHA!'), backgroundColor: Colors.red)); return; }
              var foneN = cFoneCliente.text.trim();
              var emailN = cEmailCliente.text.trim().toLowerCase();
              var jaExiste = clientes.where((c) => c['id'].toString().trim() == foneN || (c['email']??'').toString().toLowerCase().trim() == emailN).toList();
              if(jaExiste.isNotEmpty){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DUPLICADO! Já existe com status ${jaExiste.first['status']}'), backgroundColor: Colors.red)); return; }
              var novo = {'nome': cNomeCliente.text.trim(), 'id': foneN, 'fone': foneN, 'email': emailN, 'senha': cSenhaCliente.text.trim(), 'data': DateTime.now().toString().substring(0,10), 'status': 'PENDENTE', 'mensalidade': 'R\$ 29,90', 'vencimento': ''};
              clientes.add(novo); await p.setString('clientes', jsonEncode(clientes));
              try { await FirebaseFirestore.instance.collection('clientes').doc(foneN).set(novo); } catch(e){}
              showDialog(context: context, builder: (_) => AlertDialog(title: const Text('✅ Solicitação Enviada!'), content: Text('${cNomeCliente.text}, enviado!'), actions: [FilledButton(onPressed: (){ Navigator.pop(context); setState(()=> isCadastro=false); }, child: const Text('OK'))]));
            } else {
              if (cFoneCliente.text.trim().isEmpty || cSenhaCliente.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PREENCHA ID E SENHA!'), backgroundColor: Colors.red)); return; }
              var existente = clientes.where((c) => c['id'].toString().trim() == cFoneCliente.text.trim()).toList();
              if (existente.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NAO ENCONTRADO!'), backgroundColor: Colors.red)); return; }
              var cli = existente.first;
              if (cli['status']=='BLOQUEADO') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BLOQUEADO!'), backgroundColor: Colors.red)); return; }
              if (cli['status']=='PENDENTE') { showDialog(context: context, builder: (_) => AlertDialog(title: const Text('⏳ EM ANÁLISE'), content: Text('${cli['nome']} em análise.'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); return; }
              if (cli['senha'].toString().trim()!= cSenhaCliente.text.trim()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SENHA ERRADA!'), backgroundColor: Colors.red)); return; }
              nomeClienteLogado = cli['nome']; idClienteLogado = cli['id'];
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home(isAdmin: false)));
            }
          }
        }, child: carregando? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isAdmin? 'ENTRAR ADMIN' : (isCadastro? 'ENVIAR CADASTRO R\$29,90' : 'ENTRAR CLIENTE')))),
      ])))),
    );
  }
}

class Home extends StatefulWidget {
  final bool isAdmin; const Home({super.key, required this.isAdmin});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  int aba = 0;
  String filtro = 'TRIFASICO';
  String busca = '';
  String buscaCliente = '';
  String calcTipo = 'TRIFASICO';
  final marcas = ['WEG', 'ABB', 'Siemens', 'SEW', 'Voges', 'NORD', 'Kohlbach', 'Hercules', 'Búfalo', 'Eberle / GE', 'Nova', 'Linix'];
  final cCvCalc = TextEditingController();
  final cTensCalc = TextEditingController(text: '380');
  final cBusca = TextEditingController();
  final cMsg = TextEditingController();
  final cArqChat = TextEditingController();
  String chatArqBase64 = '';
  Uint8List? chatArqBytes;
  double corr = 0;
  String salaChat = 'GERAL';

  @override void initState() { super.initState(); carregarTudo(); }
  Future<void> carregarTudo() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('motores')!= null) try { motores = List<Map<String, dynamic>>.from(jsonDecode(p.getString('motores')!)); } catch(e){}
    if (p.getString('pats')!= null) try { patrocinadores = List<Map<String, dynamic>>.from(jsonDecode(p.getString('pats')!)); } catch(e){}
    if (p.getString('clientes')!= null) try { clientes = List<Map<String, dynamic>>.from(jsonDecode(p.getString('clientes')!)); } catch(e){}
    setState((){});
    try {
      var snapMot = await FirebaseFirestore.instance.collection('motores').limit(200).get();
      if(snapMot.docs.isNotEmpty){ setState((){ motores = snapMot.docs.map((d)=>d.data()).toList(); }); }
    } catch(e){}
  }
  Future<String> uploadParaStorage(Uint8List bytes, String nome) async {
    try {
      var ref = FirebaseStorage.instance.ref().child('motores/${DateTime.now().millisecondsSinceEpoch}_$nome');
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch(e){ return ''; }
  }
  Future<void> salvarTudo() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('motores', jsonEncode(motores));
    await p.setString('pats', jsonEncode(patrocinadores));
    await p.setString('clientes', jsonEncode(clientes));
    try {
      for(var m in motores){ if(m['id']!=null){ var copia = Map<String,dynamic>.from(m); copia.remove('arquivoBase64'); await FirebaseFirestore.instance.collection('motores').doc(m['id'].toString()).set(copia, SetOptions(merge: true)); } }
      for(var c in clientes){ if(c['id']!=null){ await FirebaseFirestore.instance.collection('clientes').doc(c['id'].toString()).set(c, SetOptions(merge: true)); } }
    } catch(e){}
  }

  void calcular() {
    double cv = double.tryParse(cCvCalc.text.replaceAll(',', '.'))?? 0;
    double t = double.tryParse(cTensCalc.text)?? 380;
    if (calcTipo == 'MONOFASICO') {
      if (cv > 15) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MONOFASICO MAX 15CV'), backgroundColor: Colors.red)); return; }
      if (t > 260) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MONOFASICO NÃO TEM 380V!'), backgroundColor: Colors.red)); return; }
    }
    double r = calcTipo == 'TRIFASICO'? (t <= 220? cv * 2.6 : cv * 1.52) : (t <= 130? cv * 9.5 : cv * 5.2);
    setState(() => corr = r);
  }

  void abrirForm({Map? edit, int? indexEdit}) {
    if (!widget.isAdmin && edit == null) return;
    String tipo = edit == null? filtro : edit['tipo'];
    String marca = edit == null? marcas.first : (marcas.contains(edit['marca'])? edit['marca'] : marcas.first);
    String tipoBob = edit == null? 'Imbricado' : edit['tipoBob']?? 'Imbricado';
    String camada = edit == null? 'Dupla' : edit['camada']?? 'Dupla';
    var cId = TextEditingController(text: edit?['id']?? '');
    var cModelo = TextEditingController(text: edit?['modelo']?? '');
    var cCv = TextEditingController(text: edit?['cv']?? '');
    var cCarcaca = TextEditingController(text: edit?['carcaca']?? '');
    var cData = TextEditingController(text: edit?['dataFab']?? '');
    var cIso = TextEditingController(text: edit?['isolacao']?? 'F');
    var cEntre = TextEditingController(text: edit?['entreferro']?? '');
    var cRan = TextEditingController(text: edit?['ranhuras']?? '');
    var cPac = TextEditingController(text: edit?['pacote']?? '');
    var cDext = TextEditingController(text: edit?['diamExt']?? '');
    var cDint = TextEditingController(text: edit?['diamInt']?? '');
    var cPol = TextEditingController(text: edit?['polos']?? '4');
    var cFreq = TextEditingController(text: edit?['freq']?? '60');
    var cRpm = TextEditingController(text: edit?['rpm']?? '');
    var cTen = TextEditingController(text: edit?['tensao']?? '220/380');
    var cCorr = TextEditingController(text: edit?['corrente']?? '');
    var cPasso = TextEditingController(text: edit?['passo']?? '');
    var cFios = TextEditingController(text: edit?['fios']?? '');
    var cBit = TextEditingController(text: edit?['bitola']?? '');
    var cEsp = TextEditingController(text: edit?['espiras']?? '');
    var cLig = TextEditingController(text: edit?['ligacao']?? '');
    var cFiosPrinc = TextEditingController(text: edit?['fiosPrinc']?? '');
    var cEspPrinc = TextEditingController(text: edit?['espirasPrinc']?? '');
    var cPassoPrinc = TextEditingController(text: edit?['passoPrinc']?? '');
    var cFiosAux = TextEditingController(text: edit?['fiosAux']?? '');
    var cEspAux = TextEditingController(text: edit?['espirasAux']?? '');
    var cPassoAux = TextEditingController(text: edit?['passoAux']?? '');
    var cCapP = TextEditingController(text: edit?['capPerm']?? '');
    var cCapPa = TextEditingController(text: edit?['capPartida']?? '');
    var cAnexo = TextEditingController(text: edit?['arquivo']?? '');
    String urlFotoExistente = edit?['fotoUrl']?? '';
    Uint8List? bytesNovos;
    String nomeArqNovo = '';

    if (!widget.isAdmin && edit!= null) {
      showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
        return DraggableScrollableSheet(initialChildSize: 0.95, maxChildSize: 0.95, minChildSize: 0.5, expand: false, builder: (_, scroll) {
          return ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("ID: ${edit['id']} ${edit['marca']} ${edit['cv']}CV", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(20)), child: Text("${edit['tipoBob']} | ${edit['camada']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13))),
            ])),
            const SizedBox(height: 16),
            if (edit['fotoUrl']!= null && edit['fotoUrl'].toString().isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(edit['fotoUrl'], fit: BoxFit.contain)),
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Row(children: [Expanded(child: Text('Modelo: ${edit['modelo']}')), Expanded(child: Text('Carcaça: ${edit['carcaca']}'))]),
              Row(children: [Expanded(child: Text('Polos: ${edit['polos']}')), Expanded(child: Text('RPM: ${edit['rpm']}'))]),
              Text('Fios: ${edit['fios']??edit['fiosPrinc']} | Espiras: ${edit['espiras']??edit['espirasPrinc']}'),
            ]))),
          ]);
        });
      });
      return;
    }

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setDialog) {
        return AlertDialog(
          title: Text('FICHA $tipo - $tipoBob / $camada'),
          content: SizedBox(width: 700, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: cId, decoration: const InputDecoration(labelText: 'Nº ID *', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'TRIFASICO', label: Text('TRIFASICO')), ButtonSegment(value: 'MONOFASICO', label: Text('MONOFASICO MAX 15CV'))], selected: {tipo}, onSelectionChanged: (v) => setDialog(() => tipo = v.first)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: marca, items: marcas.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(), onChanged: (v) => setDialog(() => marca = v!), decoration: const InputDecoration(labelText: 'Marca - 12 opções', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TIPO DE BOBINAGEM *', style: TextStyle(fontWeight: FontWeight.bold)),
              SegmentedButton<String>(segments: const [ButtonSegment(value: 'Imbricado', label: Text('Imbricado')), ButtonSegment(value: 'Concêntrico', label: Text('Concêntrico')), ButtonSegment(value: 'Espiral', label: Text('Espiral'))], selected: {tipoBob}, onSelectionChanged: (v) => setDialog(() => tipoBob = v.first)),
              const SizedBox(height: 8),
              const Text('CAMADA *', style: TextStyle(fontWeight: FontWeight.bold)),
              SegmentedButton<String>(segments: const [ButtonSegment(value: 'Única', label: Text('Única')), ButtonSegment(value: 'Mista', label: Text('Mista')), ButtonSegment(value: 'Dupla', label: Text('Dupla'))], selected: {camada}, onSelectionChanged: (v) => setDialog(() => camada = v.first)),
            ])),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(nomeArqNovo.isEmpty? (urlFotoExistente.isEmpty? 'Nenhuma foto' : 'Foto já salva no Storage') : nomeArqNovo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              FilledButton.icon(icon: const Icon(Icons.folder_open), label: const Text('FOTO STORAGE'), onPressed: () async {
                var result = await (FilePicker as dynamic).platform.pickFiles(withData: true, type: FileType.image);
                if (result!= null && result.files.first.bytes!= null) {
                  setDialog(() {
                    bytesNovos = result.files.first.bytes!;
                    nomeArqNovo = result.files.first.name;
                  });
                }
              })
            ]),
            if (bytesNovos!=null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.memory(bytesNovos!, height: 100)),
            if (bytesNovos==null && urlFotoExistente.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Image.network(urlFotoExistente, height: 100)),
            const Divider(),
            TextField(controller: cModelo, decoration: const InputDecoration(labelText: 'Modelo')), TextField(controller: cCv, decoration: const InputDecoration(labelText: 'CV')), TextField(controller: cCarcaca, decoration: const InputDecoration(labelText: 'Carcaça')), TextField(controller: cData, decoration: const InputDecoration(labelText: 'Data fab')), TextField(controller: cIso, decoration: const InputDecoration(labelText: 'Isol')), TextField(controller: cEntre, decoration: const InputDecoration(labelText: 'Entreferro')), TextField(controller: cRan, decoration: const InputDecoration(labelText: 'Ranhuras')), TextField(controller: cPac, decoration: const InputDecoration(labelText: 'Pacote')), TextField(controller: cDext, decoration: const InputDecoration(labelText: 'Diam Ext')), TextField(controller: cDint, decoration: const InputDecoration(labelText: 'Diam Int')), TextField(controller: cPol, decoration: const InputDecoration(labelText: 'Polos')), TextField(controller: cFreq, decoration: const InputDecoration(labelText: 'Freq')), TextField(controller: cRpm, decoration: const InputDecoration(labelText: 'RPM')), TextField(controller: cTen, decoration: const InputDecoration(labelText: 'Tensão')), TextField(controller: cCorr, decoration: const InputDecoration(labelText: 'Corrente')),
            if (tipo == 'TRIFASICO')...[TextField(controller: cFios, decoration: const InputDecoration(labelText: 'Fios Principal')), TextField(controller: cBit, decoration: const InputDecoration(labelText: 'Bitola')), TextField(controller: cEsp, decoration: const InputDecoration(labelText: 'Espiras')), TextField(controller: cPasso, decoration: const InputDecoration(labelText: 'Passo')), TextField(controller: cLig, decoration: const InputDecoration(labelText: 'Ligação'))],
            if (tipo == 'MONOFASICO')...[TextField(controller: cFiosPrinc, decoration: const InputDecoration(labelText: 'Fios Principal *')), TextField(controller: cEspPrinc, decoration: const InputDecoration(labelText: 'Espiras Principal *')), TextField(controller: cPassoPrinc, decoration: const InputDecoration(labelText: 'Passo Principal *')), TextField(controller: cFiosAux, decoration: const InputDecoration(labelText: 'Fios Auxiliar')), TextField(controller: cEspAux, decoration: const InputDecoration(labelText: 'Espiras Auxiliar')), TextField(controller: cPassoAux, decoration: const InputDecoration(labelText: 'Passo Auxiliar *')), TextField(controller: cCapP, decoration: const InputDecoration(labelText: 'Cap Perm')), TextField(controller: cCapPa, decoration: const InputDecoration(labelText: 'Cap Partida'))],
          ]))),
          actions: [FilledButton(onPressed: () async {
            if (cId.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID OBRIGATORIO!'), backgroundColor: Colors.red)); return; }
            double cvVal = double.tryParse(cCv.text)?? 0;
            if (tipo == 'MONOFASICO' && cvVal > 15) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MONO MAX 15CV'), backgroundColor: Colors.red)); return; }
            String fotoUrlFinal = urlFotoExistente;
            if (bytesNovos!= null) { fotoUrlFinal = await uploadParaStorage(bytesNovos!, nomeArqNovo); }
            var novo = {'id': cId.text.trim(), 'tipo': tipo, 'marca': marca, 'modelo': cModelo.text, 'cv': cCv.text, 'carcaca': cCarcaca.text, 'dataFab': cData.text, 'isolacao': cIso.text, 'entreferro': cEntre.text, 'ranhuras': cRan.text, 'pacote': cPac.text, 'diamExt': cDext.text, 'diamInt': cDint.text, 'polos': cPol.text, 'freq': cFreq.text, 'rpm': cRpm.text, 'tensao': cTen.text, 'corrente': cCorr.text, 'passo': cPasso.text, 'fios': cFios.text, 'bitola': cBit.text, 'espiras': cEsp.text, 'ligacao': cLig.text, 'tipoBob': tipoBob, 'camada': camada, 'fiosPrinc': cFiosPrinc.text, 'espirasPrinc': cEspPrinc.text, 'passoPrinc': cPassoPrinc.text, 'fiosAux': cFiosAux.text, 'espirasAux': cEspAux.text, 'passoAux': cPassoAux.text, 'capPerm': cCapP.text, 'capPartida': cCapPa.text, 'arquivo': nomeArqNovo.isEmpty? cAnexo.text : nomeArqNovo, 'fotoUrl': fotoUrlFinal};
            setState(() { if (indexEdit == null) motores.add(novo); else motores[indexEdit] = novo; });
            Navigator.pop(context); await salvarTudo();
          }, child: const Text('SALVAR NO FIREBASE + STORAGE'))],
        );
      });
    });
  }

  void abrirPatrocinador({Map? edit, int? idx}) {
    if (!widget.isAdmin) return;
    var cNome = TextEditingController(text: edit?['nome']?? '');
    String logoUrl = edit?['logoUrl']?? '';
    Uint8List? bytesLogo;
    String nomeLogoNovo = '';
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setDialog) {
        return AlertDialog(
          title: Text(edit==null? 'NOVO PAT ${patrocinadores.length+1}/6' : 'EDITAR PAT'),
          content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: cNome, decoration: const InputDecoration(labelText: 'Nome Empresa *', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(nomeLogoNovo.isEmpty? (logoUrl.isEmpty? 'Nenhuma logo' : 'Logo salva no Storage') : nomeLogoNovo)),
              FilledButton.icon(icon: const Icon(Icons.image), label: const Text('LOGO STORAGE'), onPressed: () async {
                var r = await (FilePicker as dynamic).platform.pickFiles(type: FileType.image, withData: true);
                if (r!= null && r.files.first.bytes!= null) {
                  setDialog(() {
                    bytesLogo = r.files.first.bytes!;
                    nomeLogoNovo = r.files.first.name;
                  });
                }
              })
            ]),
            if (bytesLogo!=null) Image.memory(bytesLogo!, height: 80),
            if (bytesLogo==null && logoUrl.isNotEmpty) Image.network(logoUrl, height: 80),
          ])),
          actions: [FilledButton(onPressed: () async {
            if (cNome.text.isEmpty) return;
            String finalLogoUrl = logoUrl;
            if(bytesLogo!=null){ finalLogoUrl = await uploadParaStorage(bytesLogo!, nomeLogoNovo); }
            var novo = {'nome': cNome.text, 'logoUrl': finalLogoUrl};
            setState(() { if (idx==null) patrocinadores.add(novo); else patrocinadores[idx]=novo; });
            salvarTudo(); Navigator.pop(context);
          }, child: const Text('SALVAR NO STORAGE'))],
        );
      });
    });
  }

  Widget buildChat1000() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(8), color: Colors.blue.shade50, child: Row(children: [const Icon(Icons.chat, size:16), const SizedBox(width:6), Expanded(child: Text('CHAT SALA: $salaChat - 1K CLIENTES', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
      DropdownButton<String>(value: salaChat, items: [const DropdownMenuItem<String>(value: 'GERAL', child: Text('GERAL - TODOS')),...clientes.where((c)=> c['status']=='APROVADO').map((c)=> DropdownMenuItem<String>(value: c['id'].toString(), child: Text(c['nome'].toString().length > 15? c['nome'].toString().substring(0,15) : c['nome'].toString()))).toList()], onChanged: (v){ if(v!=null) setState(()=> salaChat=v); })
      ])),
      Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('chat_geral').orderBy('hora', descending: false).limit(500).snapshots(), builder: (context, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var filtrados = snap.data!.docs.where((d){ var data = d.data() as Map<String,dynamic>; return (data['sala']??'GERAL') == salaChat; }).toList();
        if(filtrados.isEmpty) return Center(child: Text('Sem mensagens em $salaChat'));
        return ListView.builder(itemCount: filtrados.length, padding: const EdgeInsets.all(12), itemBuilder: (_, i){
          var data = filtrados[i].data() as Map<String,dynamic>;
          bool isMe = data['quemId']==idClienteLogado || (widget.isAdmin && data['quem']=='ADMIN');
          String nomeArq = (data['arquivoNome']??'').toString();
          bool isPdf = nomeArq.toLowerCase().endsWith('.pdf');
          String urlArq = (data['arquivoUrl']??'').toString();
          bool hasArq = urlArq.isNotEmpty || (data['arquivoBase64']??'').toString().isNotEmpty;
          return Align(alignment: isMe? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical:4), padding: const EdgeInsets.all(10), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.75), decoration: BoxDecoration(color: data['quem']=='ADMIN'? const Color(0xFF0D47A1) : (isMe? Colors.green.shade200 : Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${data['quem']}", style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: data['quem']=='ADMIN'? Colors.white : Colors.black)),
            Text("${data['texto']}", style: TextStyle(color: data['quem']=='ADMIN'? Colors.white : Colors.black)),
            if(hasArq) Padding(padding: const EdgeInsets.only(top:6), child: isPdf? Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.picture_as_pdf, color: Colors.red), const SizedBox(width:6), Expanded(child: Text(nomeArq, style: const TextStyle(fontSize:12))) ])) : urlArq.isNotEmpty? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(urlArq, height:150, fit: BoxFit.cover)) : const SizedBox())
          ])));
        });
      })),
      if (chatArqBytes!=null) Container(padding: const EdgeInsets.all(8), color: Colors.yellow.shade100, child: Row(children: [Icon(cArqChat.text.toLowerCase().endsWith('.pdf')? Icons.picture_as_pdf : Icons.image, color: Colors.red), const SizedBox(width:6), Expanded(child: Text('Pronto: ${cArqChat.text}', style: const TextStyle(fontSize:12, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.close, size:18), onPressed: () => setState((){ chatArqBytes=null; cArqChat.clear(); })) ])),
      Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade100, child: Row(children: [
        IconButton(icon: const Icon(Icons.attach_file), tooltip: 'Foto ou PDF para STORAGE', onPressed: () async {
          var result = await (FilePicker as dynamic).platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','pdf'], withData: true);
          if (result!= null && result.files.isNotEmpty && result.files.first.bytes!=null) {
            if (result.files.first.bytes!.length > 4000000) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ARQUIVO MUITO GRANDE! Máx 4MB'), backgroundColor: Colors.red)); return; }
            setState(() { cArqChat.text = result.files.first.name; chatArqBytes = result.files.first.bytes!; });
          }
        }),
        Expanded(child: TextField(controller: cMsg, decoration: InputDecoration(hintText: chatArqBytes==null? 'Mensagem em $salaChat...' : 'Anexo: ${cArqChat.text}', border: const OutlineInputBorder(), isDense: true))),
        const SizedBox(width: 6),
        IconButton(style: IconButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white), icon: const Icon(Icons.send), onPressed: () async {
          if (cMsg.text.trim().isEmpty && chatArqBytes==null) return;
          try {
            String urlFinal = '';
            if(chatArqBytes!=null){ urlFinal = await uploadParaStorage(chatArqBytes!, cArqChat.text); }
            await FirebaseFirestore.instance.collection('chat_geral').add({
              'texto': cMsg.text.isEmpty? (cArqChat.text.endsWith('.pdf')? '📄 PDF: ${cArqChat.text}' : '📷 Foto: ${cArqChat.text}') : cMsg.text,
              'quem': widget.isAdmin? 'ADMIN' : nomeClienteLogado,
              'quemId': idClienteLogado,
              'sala': salaChat,
              'arquivoUrl': urlFinal,
              'arquivoNome': cArqChat.text,
              'hora': FieldValue.serverTimestamp()
            });
            cMsg.clear(); setState((){ cArqChat.clear(); chatArqBytes=null; });
          } catch(e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red)); }
        })])),
    ]);
  }

  @override Widget build(BuildContext context) {
    var filt = motores.where((e) { if (e['tipo']!= filtro) return false; if (busca.isEmpty) return true; return e['id'].toString().toLowerCase().contains(busca.toLowerCase()) || e['marca'].toString().toLowerCase().contains(busca.toLowerCase()); }).toList();
    var filtClientes = clientes.where((c) { if (buscaCliente.isEmpty) return true; return c['nome'].toString().toLowerCase().contains(buscaCliente.toLowerCase()) || c['id'].toString().contains(buscaCliente); }).toList();
    Widget telaMotores = Column(children: [
      if (patrocinadores.isNotEmpty) Container(height: 70, color: Colors.amber.shade50, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: patrocinadores.length, itemBuilder: (_, i) { var pat = patrocinadores[i]; return Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)), child: Row(children: [if (pat['logoUrl']!= null && pat['logoUrl'].toString().isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(pat['logoUrl'], height: 30, width: 30, fit: BoxFit.cover)), const SizedBox(width: 6), Text(pat['nome'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])) ;})),
      Padding(padding: const EdgeInsets.all(8), child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'TRIFASICO', label: Text('TRIFASICO')), ButtonSegment(value: 'MONOFASICO', label: Text('MONOFASICO MAX 15CV'))], selected: {filtro}, onSelectionChanged: (v) => setState(() => filtro = v.first))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(controller: cBusca, decoration: const InputDecoration(hintText: 'Buscar ID, MARCA (12 marcas) - 10K', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => busca = v))),
      Expanded(child: ListView.builder(itemCount: filt.length, itemBuilder: (context, i) { var m=filt[i]; return Card(child: ListTile(leading: m['fotoUrl']!=null && m['fotoUrl'].toString().isNotEmpty? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(m['fotoUrl'], width: 40, height: 40, fit: BoxFit.cover)) : CircleAvatar(child: Text(m['id'].toString().isEmpty? '?' : m['id'][0])), title: Text("ID:${m['id']} ${m['marca']} ${m['cv']}CV ${m['tipoBob']}/${m['camada']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text("Bob: ${m['tipoBob']} | Camada: ${m['camada']} | Fios:${m['fios']??m['fiosPrinc']}", style: const TextStyle(fontSize: 11)), onTap: () => abrirForm(edit: m, indexEdit: motores.indexOf(m)))); })),
    ]);
    Widget telaPat = Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PAT ${patrocinadores.length}/6 - STORAGE', style: const TextStyle(fontWeight: FontWeight.bold)), if (widget.isAdmin) FilledButton.icon(icon: const Icon(Icons.add), label: const Text('ADD'), onPressed: () => abrirPatrocinador())])),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: patrocinadores.length, itemBuilder: (_, i) { var pat = patrocinadores[i]; return Card(child: InkWell(onTap: () => abrirPatrocinador(edit: pat, idx: i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [if (pat['logoUrl']!= null && pat['logoUrl'].toString().isNotEmpty) Image.network(pat['logoUrl'], height: 60), Text(pat['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]))); })),
    ]);
    Widget telaClientes = Column(children: [
      Container(padding: const EdgeInsets.all(10), color: Colors.green.shade50, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CLIENTES ${filtClientes.length}/1000 - R\$29,90', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)), Text('PEND: ${clientes.where((c) => c['status']=='PENDENTE').length}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))])),
      Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(hintText: 'Buscar cliente - 1000', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => buscaCliente = v))),
      Expanded(child: ListView.builder(itemCount: filtClientes.length, itemBuilder: (_, i) {
        var c = filtClientes[i]; int realIndex = clientes.indexOf(c);
        return Card(child: ListTile(
          title: Text("${c['nome']} - ${c['status']}", style: TextStyle(fontWeight: FontWeight.bold, color: c['status']=='APROVADO'? Colors.green : Colors.orange, fontSize: 12)),
          subtitle: Text('ID/Fone: ${c['id']} | Email: ${c['email']??''}'),
          trailing: widget.isAdmin? PopupMenuButton(onSelected: (v) async { if (v=='aprovar'){ var venc = DateTime.now().add(const Duration(days: 30)); String vencStr = "${venc.day.toString().padLeft(2,'0')}/${venc.month.toString().padLeft(2,'0')}/${venc.year}"; setState(() { clientes[realIndex]['status']='APROVADO'; clientes[realIndex]['vencimento']=vencStr; }); salvarTudo(); } if (v=='bloquear'){ setState((){ clientes[realIndex]['status']='BLOQUEADO'; }); salvarTudo(); } if (v=='excluir'){ String idDel = clientes[realIndex]['id'].toString(); try{ await FirebaseFirestore.instance.collection('clientes').doc(idDel).delete(); }catch(e){} setState((){ clientes.removeAt(realIndex); }); salvarTudo(); } if (v=='renovar'){ var venc = DateTime.now().add(const Duration(days: 30)); String vencStr = "${venc.day.toString().padLeft(2,'0')}/${venc.month.toString().padLeft(2,'0')}/${venc.year}"; setState((){ clientes[realIndex]['vencimento']=vencStr; clientes[realIndex]['status']='APROVADO'; }); salvarTudo(); } }, itemBuilder: (_) => [const PopupMenuItem(value: 'aprovar', child: Text('✅ APROVAR')), const PopupMenuItem(value: 'renovar', child: Text('🔄 RENOVAR +30 DIAS')), const PopupMenuItem(value: 'bloquear', child: Text('🚫 BLOQUEAR')), const PopupMenuItem(value: 'excluir', child: Text('🗑️ EXCLUIR DEFINITIVO'))]) : null));
      })),
    ]);
    Widget telaCalc = ListView(padding: const EdgeInsets.all(16), children: [SegmentedButton<String>(segments: const [ButtonSegment(value: 'TRIFASICO', label: Text('TRIFASICO')), ButtonSegment(value: 'MONOFASICO', label: Text('MONOFASICO MAX 15CV'))], selected: {calcTipo}, onSelectionChanged: (v) => setState(() => calcTipo = v.first)), const SizedBox(height: 8), TextField(controller: cCvCalc, decoration: const InputDecoration(labelText: 'CV *', border: OutlineInputBorder())), const SizedBox(height: 8), TextField(controller: cTensCalc, decoration: const InputDecoration(labelText: 'Tensão (Mono: 110/127/220)', border: OutlineInputBorder())), const SizedBox(height: 8), FilledButton(onPressed: calcular, child: const Text('CALCULAR CORRENTE')), const SizedBox(height: 10), Text('${corr.toStringAsFixed(2)} A', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))]);
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, title: Text("${widget.isAdmin? 'ADMIN' : nomeClienteLogado} - ${motores.length}/10000 | ${clientes.length}/1000", style: const TextStyle(fontSize: 12)), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login())))]),
      bottomNavigationBar: NavigationBar(selectedIndex: aba, onDestinationSelected: (v) => setState(() => aba = v), destinations: const [NavigationDestination(icon: Icon(Icons.list), label: 'Motores'), NavigationDestination(icon: Icon(Icons.chat), label: 'Chat 1K'), NavigationDestination(icon: Icon(Icons.star), label: 'Patroc.'), NavigationDestination(icon: Icon(Icons.people), label: 'Clientes 1K'), NavigationDestination(icon: Icon(Icons.calculate), label: 'Calc')]),
      floatingActionButton: aba==0 && widget.isAdmin? FloatingActionButton.extended(onPressed: () => abrirForm(), label: Text('NOVO $filtro'), icon: const Icon(Icons.add)) : aba==2 && widget.isAdmin? FloatingActionButton.extended(onPressed: () => abrirPatrocinador(), label: const Text('ADD PAT'), icon: const Icon(Icons.star)) : null,
      body: [telaMotores, buildChat1000(), telaPat, telaClientes, telaCalc][aba],
    );
  }
}