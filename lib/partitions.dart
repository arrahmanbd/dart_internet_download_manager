
List<Partition> calculatePartitions(int contentLength, int numParts, int partSize) {
  final partitions = <Partition>[];
  final partLength = (contentLength / numParts).ceil();

  for (var i = 0; i < numParts; i++) {
    final start = i * partLength;
    final end = (i + 1) * partLength - 1;

    if (end > contentLength - 1) {
      partitions.add(Partition(start, contentLength - 1));
    } else {
      partitions.add(Partition(start, end));
    }
  }

  return partitions;
}

class Partition {
  final int start;
  final int end;

  Partition(this.start, this.end);
}
