//ValueListenableBuilder to listen to page changes
//ValueNotifier to hold the current page index(data)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);