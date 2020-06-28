import 'package:flutter/material.dart';

class PlaceHolderListItem extends StatelessWidget {
  final Widget trailing;

  PlaceHolderListItem({this.trailing});

  Widget _placeHolderWidget() {
    return Container(
      width: 50,
      height: 10,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          color: Colors.grey[200]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        splashColor: Colors.yellow,
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            radius: 25,
          ),
          title: _placeHolderWidget(),
          subtitle: _placeHolderWidget(),
          trailing: trailing != null ?
          trailing : Checkbox(
            value: false,
          ),
        ),
      ),
    );
  }
}
