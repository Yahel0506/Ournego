import 'dart:io' show SocketException;

bool isSocketException(Object error) => error is SocketException;
