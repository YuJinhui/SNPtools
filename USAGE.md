# Prep sample BAM files:

    cd /Users/mfc/git.repos/SNPtools/sample-files/bam/
    samtools view -hb R500.good.bam \
      A01:10001-20000 \
      A02:10001-20000 \
      A03:30001-40000 \
      A04:10001-20000 \
      A05:10001-20000 \
      A06:10001-20000 \
      A07:60001-70000 \
      A08:10001-20000 \
      A09:1-10000 \
      A10:90001-100000 > R500.10kb.bam
    samtools view -hb IMB211.good.bam \
      A01:10001-20000 \
      A02:10001-20000 \
      A03:30001-40000 \
      A04:10001-20000 \
      A05:10001-20000 \
      A06:10001-20000 \
      A07:60001-70000 \
      A08:10001-20000 \
      A09:1-10000 \
      A10:90001-100000 > IMB211.10kb.bam
    samtools index R500.10kb.bam
    samtools index IMB211.10kb.bam

# Identify Polymorphisms

    BIN=/Users/mfc/git.repos/SNPtools/bin
    BASE_DIR=/Users/mfc/git.repos/SNPtools/sample-files
    FA_DIR=$BASE_DIR/fa
    BAM_DIR=$BASE_DIR/bam
    OUT_DIR=$BASE_DIR/output
    PAR1=R500
    PAR2=IMB211

    for ID in $PAR1 $PAR2
    do
        $BIN/SNPfinder/snp_finder.pl \
          --id        $ID \
          --bam       $BAM_DIR/$ID.10kb.bam \
          --fasta     $FA_DIR/B.rapa_genome_sequence_0830.fa \
          --seq_list  A01,A02,A03,A04,A05,A06,A07,A08,A09,A10 \
          --out_dir   $OUT_DIR \
          --snp_min   0.66 \
          --indel_min 0.33 \
          --threads   3 \
          --verbose

        for SNP_FILE in $OUT_DIR/snps/$ID.*.snps.nogap.gap.csv; do
            $BIN/SNPfinder/02.0.filtering_SNPs_by_pos.pl $SNP_FILE
        done
    done

    $BIN/Coverage/reciprocal_coverage.pl \
      --bam      $BAM_DIR/$PAR1.10kb.bam \
      --par1     $PAR1 \
      --par2     $PAR2 \
      --par1_bam $BAM_DIR/$PAR1.10kb.bam \
      --par2_bam $BAM_DIR/$PAR2.10kb.bam \
      --seq_list A01,A02,A03,A04,A05,A06,A07,A08,A09,A10 \
      --out_dir  $OUT_DIR \
      --threads  3 \
      --verbose

    for CHR in A0{1..9} A10; do
        $BIN/SNPfinder/coverage_filter.pl \
          --chr  $CHR \
          --snp1 $OUT_DIR/snps/$PAR1.$CHR.snps.nogap.gap.FILTERED.csv \
          --snp2 $OUT_DIR/snps/$PAR2.$CHR.snps.nogap.gap.FILTERED.csv \
          --par1 $PAR1 \
          --par2 $PAR2 \
          --out  $OUT_DIR
    done

    $BIN/SNPfinder/classify-snps.r $OUT_DIR/master_snp_lists

    mkdir $OUT_DIR/snp_master
    for CHR in A0{1..9} A10; do
        grep -ve "NOT" \
        $OUT_DIR/master_snp_lists/master_snp_list.$PAR1.vs.$PAR2.$CHR.classified \
        > $OUT_DIR/snp_master/polyDB.$CHR &
    done
