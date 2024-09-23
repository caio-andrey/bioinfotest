#!/bin/bash
# Todos os arquivos precisam estar dentro da mesma pasta do script, os fastq, ref e o arquivo BED.
# Você precisa saber o codigo do seu banco do snpEff para passar no inicido do script. Pesquisa antes usando o codigo "snpEff download" e veja na lista

VERSION="Version 1.0"

Help()
{
   # Display Help
   echo "Chamada e Anotação de Variante."
   echo
   echo "Uso: script_vcf.sh [-g|-f|-r|-t|-o]"
   echo "options:"
   echo "-g     Reference"
   echo "-f     R1"
   echo "-r     R2"
   echo "-t     Codigo do banco do snpEff"
   echo	"-o     Como voce quer chamar os arquivos de saida"
   echo "-v     Print version"
   echo "-h     Help"
   echo 
}


while getopts g:f:r:t:o:vh option
do
    case "${option}" in
        g) reference=${OPTARG};;
        f) R1=${OPTARG};;
        r) R2=${OPTARG};;
        t) snpeff_code=${OPTARG};;
        o) output=${OPTARG};;
        v) echo "$VERSION"
	    exit ;;
        h) Help
            exit;;
        \?) 
         echo "Error"
         exit;;
    esac
done 


# Verificação de argumentos
if [ -z "$reference" ] || [ -z "$R1" ] || [ -z "$R2" ] || [ -z "$snpeff_code" ] || [ -z "$output" ]; then
    echo "$0, $VERSION - É necessário fornecer os argumentos completos"
    Help
    exit 1
fi

echo "A chamada de varianta vai começar !!"


## FastQC

# Controle de Qualidade
fastqc -f fastq ${R1} 
fastqc -f fastq ${R2} 

echo "Controle de qualidado feito para os arquivos Forward e Reverse"

## BWA 

# Indexar o arquivo de referência se necessário
bwa index ${reference}

# Alinhar os FASTQ na referência  
bwa mem ${reference} ${R1} ${R2} > ${output}.sam

echo "Alinhamento concluido, arquivo ${output}.sam gerado!"

## Samtools 
 
# Manipular os arquivos SAM e BAM
samtools view -b ${output}.sam > ${output}.bam
samtools sort ${output}.bam > ${output}_sorted.bam
samtools index ${output}_sorted.bam

echo "Arquivos sam e bam gerado!"

## Picard

# Add o RGLB que estava faltando no arquivo das amostras, aqui foi usado uma generica
## java -jar ~/bin/picard.jar AddOrReplaceReadGroups 
picard AddOrReplaceReadGroups \
I=${output}_sorted.bam \
O=${output}_sorted_RG.bam \
RGID=id \
RGLB=${output}_library \
RGPL=illumina \
RGPU=unit \
RGSM=${output}_name

echo "Por ser necessario foi add o RGLB ao arquivo ${output}_sorted.bam"


# Remover as duplicatas que podem caussar falso positivo
## java -jar ~/bin/picard.jar MarkDuplicates 
picard MarkDuplicates \
I=${output}_sorted_RG.bam \
O=${output}_dedup.bam \
M=${output}_metrics.txt \
REMOVE_DUPLICATES=true

echo "Foi removido as duplicatas do arquivo ${output}_sorted_RG.bam"

## Samtools

# Necessario indexar o arquivo novamente para ser input no freebayes

samtools index ${output}_dedup.bam 
 
echo "${output}_dedup.bam foi indexado ao samtools!"

## FreeBayes 

# Chamada de variantes
# A flag "-p" entra na questão da ploidia do organismo
# A flag "--target" é para aceitar o arquivo BED que aponta as regioes de interesse para chamada de variante
freebayes -f ${reference} ${output}_dedup.bam -p 2 --target BRCA.bed > ${output}.vcf

echo "Foi realizado a chamada de variante e o arquivo ${output}.vcf foi gerado!"

## SnpEff 

# Fazer a anotação de variantes

snpEff download ${snpeff_code} -v

echo "O banco de dados ${snpeff_code} foi baixado no snpEff!"

snpEff -v -stats ${output}_vcf_stats.html ${snpeff_code} ${output}.vcf > ${output}_ann.vcf

echo "Anotação concluida!!"
