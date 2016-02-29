#include <cstdio>
#include <cstdlib>
#include "SyncedMemory.h"
#include "Timer.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK {\
	auto e = cudaDeviceSynchronize();\
	if (e != cudaSuccess) {\
		printf("At " __FILE__ ":%d, %s\n", __LINE__, cudaGetErrorString(e));\
		abort();\
	}\
}

//__device__ int a[3] = { 0, 1, 2 };

__global__ void SomeTransform(char *input_gpu, int fsize) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	 
	//if (idx < fsize && input_gpu[idx] != '\n') {
	//	input_gpu[idx] = '!';
	//}
	
	//**�N�r���������j�g**//
	if (idx < fsize && input_gpu[idx] != '\n'){
		if (input_gpu[idx] >= 'a' && input_gpu[idx] <= 'z'){
			input_gpu[idx] -= 32;
		}
	}

}

int main(int argc, char **argv)
{
	// init, and check
	if (argc != 2) {
		printf("Usage %s <input text file>\n", argv[0]);
		abort();
	}
	FILE *fp = fopen(argv[1], "r");
	if (!fp) {
		printf("Cannot open %s", argv[1]);
		abort();
	}
	// get file size
	fseek(fp, 0, SEEK_END);//���NŪ�g��m�����ɧ�
	size_t fsize = ftell(fp); //�A�Ǧ^�ɮץثe��Ū�g��m(�ɧ�) ->�o���ɮת���
	fseek(fp, 0, SEEK_SET);//�A�q�Y�}�lŪ

	// read files
	MemoryBuffer<char> text(fsize+1);
	auto text_smem = text.CreateSync(fsize);
	CHECK;
	fread(text_smem.get_cpu_wo(), 1, fsize, fp);
	text_smem.get_cpu_wo()[fsize] = '\0';
	fclose(fp);

	// TODO: do your transform here
	char *input_gpu = text_smem.get_gpu_rw();
	
	// An example: transform the first 64 characters to '!'
	// Don't transform over the tail
	// And don't transform the line breaks
	

	SomeTransform<<<102, 32>>>(input_gpu, fsize);  //2 gridDim.x, 32 blockDim.x

	puts(text_smem.get_cpu_ro());
	
	return 0;
}
