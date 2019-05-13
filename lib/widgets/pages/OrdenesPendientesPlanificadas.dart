import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sispromovil/models/PendientesPlanificadasModel.dart';
import 'package:intl/intl.dart';
import 'package:sispromovil/blocs/plantas/BlocPlanta.dart';
import 'package:sispromovil/blocs/busqueda/BlocBusqueda.dart';
import 'package:sispromovil/widgets/pages/DetalleOT.dart';

class OrdenesPendientesPlanificadas extends StatefulWidget {
  static const String routeName = '/pendientesPlanificadas';
  @override
  _OrdenesPendientesPlanificadas createState() => _OrdenesPendientesPlanificadas();
}

class _OrdenesPendientesPlanificadas extends State<OrdenesPendientesPlanificadas> {
  PendientesPlanificadasModel itemsPendientesPlanificadas;
  int totalItems = 0;
  int parcialItems = 0;
  String baseUrl;
  String plantaActual;
  String plantaAnterior;
  String filtroBusq = '';

  @override
  void initState() {
    super.initState();
    blocPlanta.servidor.listen((servidor) {
      baseUrl = servidor + '/pendientesPlanificadas';
      plantaActual = servidor;
      plantaAnterior = servidor;
      _obtenerPlanificadas();      
    });

    blocBusquedas.filtro.listen((filtro) {
      filtroBusq = filtro;
      _obtenerPlanificadas();      
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _obtenerPlanificadas() async {
    if(plantaActual != plantaAnterior) {
      itemsPendientesPlanificadas = null;
      totalItems = 0;
      parcialItems = 0;
    }

    var response = await http.get('$baseUrl');
    
    if(response.statusCode == 200) {
      if(mounted) {
        setState(() {
          var decodeJson = jsonDecode(response.body);
          if(itemsPendientesPlanificadas == null) {
            itemsPendientesPlanificadas = PendientesPlanificadasModel.fromJson(decodeJson);
            totalItems = itemsPendientesPlanificadas.totalRegistros;
          } else {
            itemsPendientesPlanificadas.data.addAll(PendientesPlanificadasModel.fromJson(decodeJson).data);
          }
          parcialItems =itemsPendientesPlanificadas.data.length;
          plantaAnterior = plantaActual;
        });
      }
            

      if(filtroBusq.isNotEmpty && itemsPendientesPlanificadas.data.isNotEmpty) {
        itemsPendientesPlanificadas.data.map((maquina) {
          if(maquina.ots.isNotEmpty) {
            maquina.ots.retainWhere((ot) {
              return ot.id == filtroBusq || ot.cliente.toLowerCase().contains(filtroBusq) || ot.trabajo.toLowerCase().contains(filtroBusq);
            });
          }
        }).toList();
        itemsPendientesPlanificadas.data.retainWhere((maquina) {
          return maquina.ots.isNotEmpty;
        });
      } 
    } else {
      print('error');
    }
  }

  String _hsSexagesimales(double hs) {
    var minutos = ((hs - hs.floor()) * 60).round();
    String strMinutos = '';
    minutos<10 ? strMinutos = '0' + minutos.toString() :strMinutos =minutos.toString();
    return hs.floor().toString() + ':' + strMinutos; 
  }


  //con card
  Widget _itemOT(Ots ot) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    return Container(
      width: anchoPantalla * 0.8,
      child: ot.id != '' 
        ? GestureDetector(
          onTap: () { Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalleOT(id: ot.id, subID: ot.subId, cliente: ot.cliente, producto: ot.trabajo, cantPedida: ot.cantidadProducto, fechaOT: ot.fechaOT, fechaEntrega: ot.fechaEntrega)
                    ));
          },
          child: Card(      
            elevation: 10,
            margin: EdgeInsets.fromLTRB(2, 4, 2, 4),
            child: Padding(
              padding: EdgeInsets.fromLTRB(6,3,6,3),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('OT: ${ot.id}  SubOT: ${ot.subId}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${ot.cliente}', textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '${ot.cantidadProducto} un - ${ot.trabajo}', 
                      textAlign: TextAlign.start, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      maxLines: 2),
                    Row(
                      children: <Widget>[
                        Text('Fecha OT: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(DateTime.parse(ot.fechaOT))}',
                          style: TextStyle(fontSize: 12)
                        ),
                        Text('   Fecha Ent: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(DateTime.parse(ot.fechaEntrega))}',
                          style: TextStyle(fontSize: 12),)
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text('Inicio: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${DateFormat('dd/MM/yyyy hh:mm').format(DateTime.parse(ot.fechaInicio))}', style: TextStyle(fontSize: 12)),
                        Text('    Hs Prog: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${_hsSexagesimales(ot.horasTotales)}', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text('Cant Prog: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${ot.cantBuenasProg.floor()}', style: TextStyle(fontSize: 12)),
                      ],
                    )
                  ],
                )
              )
            ),
        )
          : Card(  
            color: Color(0x44888888), 
            elevation: 10,
            margin: EdgeInsets.fromLTRB(2, 4, 2, 4),
            child: Padding(
              padding: EdgeInsets.fromLTRB(6,3,6,3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('ASIGNADO A RECURSO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Inicio: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), ),
                      Text('${DateFormat('dd/MM/yyyy hh:mm').format(DateTime.parse(ot.fechaInicio))}', style: TextStyle(fontSize: 10)),
                      Text('   Fin: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      Text('${DateFormat('dd/MM/yyyy hh:mm').format(DateTime.parse(ot.fechaFin))}', style: TextStyle(fontSize: 10)),
                    ],
                  )
                ],
              )
            )
          )
    );
  }

  Widget _listaTrabajos(Data recurso) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      height: 160,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: Colors.grey[400]))
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(recurso.maquina, style:TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).primaryColor), textAlign: TextAlign.start,),
            Flexible(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recurso.ots.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(0,4,4,4),
                    child: _itemOT(recurso.ots[index])
                  );
                },
              )
            )            
          ],
        ),
      )
    );
  }


  Widget _listaRecursos() {
    return
    parcialItems > 0
    ? ListView(
      children: itemsPendientesPlanificadas.data.map((recurso) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: _listaTrabajos(recurso)
        )).toList()
      )
    : Container(width: 0, height: 0);
      
  }

 @override
 Widget build(BuildContext context) {
  return Column(
    children: <Widget>[
      Flexible(
        child: _listaRecursos()       
      )
    ],
  );
 }
}