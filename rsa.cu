#include <stdlib.h>
#include <stdio.h>
//#include <math.h>

//#define DEBUG

//Variablen
#define p 3
#define q 5
#define n 15
#define e 3
#define v 3
#define z 8
#define anzahl_Texte 80
#define count_cores 8

//__device__ long int klartexte[anzahl_Texte];
//__device__ long int klartexte_pruefung[anzahl_Texte];
//__device__ long int geheimtexte[anzahl_Texte];

/*
Klartext: K
Geheimtext: G
Verschluesselung: G = K^v mod n
Entschluesselung: K = G^e mod n

Index des CUDA Kerns: blockIdx.x blockIdx.y

*/

static void HandleError( cudaError_t err, const char *file, int line ) {
	if (err != cudaSuccess) {
		printf( "%s in %s at line %d\n", cudaGetErrorString( err ), file, line );
		exit( EXIT_FAILURE );
	}
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

__global__ void verschluessselung(int klartexte[], int geheimtexte[])
{
	int i, j, multi, x;
	
	int block_length = anzahl_Texte/count_cores;
	
	for (i = 0 ; i < block_length; i++)
	{
		//Integer hoch 103 ist zu hoch!
		//geheimtexte[i+blockIdx.x*block_length] = (int)mypow(klartexte[i+blockIdx.x*block_length],3) % 15;
		//geheimtexte[i+blockIdx.x*block_length] = mypow(,v);
		//geheimtexte[i+blockIdx.x*block_length] = (klartexte[i+blockIdx.x*block_length]*klartexte[i+blockIdx.x*block_length]*klartexte[i+blockIdx.x*block_length]) % 15;
		
		
		multi = x  = klartexte[i+blockIdx.x*block_length];
		for (j = 1; j < v; j++)
			x *= multi;
		
		geheimtexte[i+blockIdx.x*block_length] = x % n;
		
	}
}


__global__ void entschluessselung(int geheimtexte[], int klartexte_pruefung[])
{
	int i, j, multi, x;
	
	int block_length = anzahl_Texte/count_cores;

	for (i = 0 ; i < block_length; i++)
	{
		//Integer hoch 103 ist zu hoch!
		//klartexte_pruefung[i+blockIdx.x*block_length] = (int)mypow(geheimtexte[i+blockIdx.x*block_length],e) % n;
		//klartexte_pruefung[i+blockIdx.x*block_length] = (geheimtexte[i+blockIdx.x*block_length]*geheimtexte[i+blockIdx.x*block_length]*geheimtexte[i+blockIdx.x*block_length]) % n;
		
		
		multi = x  = geheimtexte[i+blockIdx.x*block_length];
		for (j = 1; j < e; j++)
			x *= multi;
		
		klartexte_pruefung[i+blockIdx.x*block_length] = x % n;
		
	}
}

int main(void) {
	int i, j;
	cudaEvent_t start, stop;
	float elapsedTime;
	
	int klartexte[anzahl_Texte];
	int klartexte_pruefung[anzahl_Texte];
	int geheimtexte[anzahl_Texte];

	//Klartetexte Array belegen
	//rand initialisieren
	srand((unsigned)time(NULL));
	for (i = 0; i < anzahl_Texte; i ++)
	{
		klartexte[i] = i % 11;		//Zahlen nicht  zu gross waehlen
	}
	
	printf("Die Klartexte:\n");
	for (i = 0; i < anzahl_Texte; i++)
	{
		printf("%ld, ", klartexte[i]);
	}
	printf("\n\n");

	int *dev_klartexte, *dev_geheimtexte, *dev_klartexte_pruefung;

	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));



	HANDLE_ERROR(cudaEventRecord(start, 0));

        HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte, sizeof(klartexte)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_geheimtexte, sizeof(geheimtexte)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte_pruefung, sizeof(klartexte_pruefung)));

        HANDLE_ERROR(cudaMemcpy(dev_klartexte, klartexte, sizeof(klartexte), cudaMemcpyHostToDevice));
        //HANDLE_ERROR(cudaMemcpy(dev_matN, matN, sizeof(matN), cudaMemcpyHostToDevice));

	dim3 blocks(count_cores, 1);

	verschluessselung<<<blocks, 1>>>(dev_klartexte, dev_geheimtexte);

        HANDLE_ERROR(cudaMemcpy(geheimtexte, dev_geheimtexte, sizeof(geheimtexte), cudaMemcpyDeviceToHost));
		
		printf("Die Klartexte wurden verschluesselt.\n\nGeheimtexte:\n");
		for (i = 0; i < anzahl_Texte; i++)
		{
			printf("%ld, ", geheimtexte[i]);
		}
		printf("\n\n");
		
		entschluessselung<<<blocks, 1>>>(dev_geheimtexte, dev_klartexte_pruefung);
		
		HANDLE_ERROR(cudaMemcpy(klartexte_pruefung, dev_klartexte_pruefung, sizeof(klartexte_pruefung), cudaMemcpyDeviceToHost));
		

	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));
	
	printf("Die Geheimtexte wurden entschluesselt.\n\Klartexte:\n");
		for (i = 0; i < anzahl_Texte; i++)
		{
			printf("%ld, ", klartexte_pruefung[i]);
		}
		printf("\n\n");

	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("Elapsed time: %3.1f ms\n", elapsedTime);



	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	

	return EXIT_SUCCESS;
}
