enum BulkVoidStatus { berhasil, gagal, belumDipastikan, belumDiproses }

class SetoranVoidOutcome {
  const SetoranVoidOutcome(this.id, this.status, [this.message]);
  final String id;
  final BulkVoidStatus status;
  final String? message;
}

class BulkVoidResult {
  BulkVoidResult(Iterable<SetoranVoidOutcome> outcomes)
      : outcomes = List.unmodifiable(outcomes);
  final List<SetoranVoidOutcome> outcomes;
  int get berhasil =>
      outcomes.where((o) => o.status == BulkVoidStatus.berhasil).length;
  Set<String> get remainingIds => {
        for (final outcome in outcomes)
          if (outcome.status != BulkVoidStatus.berhasil) outcome.id,
      };
}
