#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <cuda_runtime.h>

// TODO: Implement function to search for all nonces from 1 through MAX_NONCE (inclusive) using CUDA Threads
__global__ void findNonce(BYTE *d_block_content, int current_length, BYTE *block_hash, uint64_t *index, BYTE *dif,int* check) {
	uint64_t thread_id = blockIdx.x * blockDim.x + threadIdx.x;
	BYTE d_block_content_copy[BLOCK_SIZE];
	d_strcpy((char*)d_block_content_copy,(char*) d_block_content);
	BYTE d_block_hash[SHA256_HASH_SIZE];
	uint64_t nonce = thread_id;
	char nonce_string[NONCE_SIZE];
	intToString(nonce, nonce_string);
	d_strcpy((char*) d_block_content_copy + current_length, nonce_string);
	if (*check == 0) {
		return;
	}
	apply_sha256(d_block_content_copy, d_strlen((const char*)d_block_content_copy),d_block_hash, *check);
	if (compare_hashes(d_block_hash, dif) <= 0) {
			atomicExch(check, 0);
			*index = nonce;
			memcpy(block_hash, d_block_hash, SHA256_HASH_SIZE);
		}
}

void getParam(int& numBlocks, int& numThreads, int numItems) {
    cudaDeviceProp prop;
    cudaError_t ret;
	ret = cudaGetDeviceProperties(&prop, 0);

    if (ret != cudaSuccess) {
        printf("cudaGetDeviceProperties failed:");
        exit(1);
    }
    numThreads = prop.maxThreadsPerBlock/2;
    numBlocks = numItems / numThreads;
	if (numItems % numThreads) 
		++numBlocks;
}

int main(int argc, char **argv) {
	BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
			tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
			tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE], block_content[BLOCK_SIZE];

	int numBlocks, numThreads;
	cudaDeviceProp prop;
    cudaError_t ret;
	ret = cudaGetDeviceProperties(&prop, 0);

    if (ret != cudaSuccess) {
        printf("cudaGetDeviceProperties failed:");
        exit(1);
    }
    numThreads = prop.maxThreadsPerBlock/2;
    numBlocks = int(MAX_NONCE) / numThreads;
	if (int(MAX_NONCE) % numThreads) 
		++numBlocks;

	// Top hash
	apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
	apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
	apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
	apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);
	strcpy((char *)tx12, (const char *)hashed_tx1);
	strcat((char *)tx12, (const char *)hashed_tx2);
	apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
	strcpy((char *)tx34, (const char *)hashed_tx3);
	strcat((char *)tx34, (const char *)hashed_tx4);
	apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
	strcpy((char *)tx1234, (const char *)hashed_tx12);
	strcat((char *)tx1234, (const char *)hashed_tx34);
	apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

	// prev_block_hash + top_hash
	strcpy((char*)block_content, (const char*)prev_block_hash);
	strcat((char*)block_content, (const char*)top_hash);
	size_t current_length;
	current_length = strlen((char*) block_content);

	cudaEvent_t start, stop;
	BYTE *d_block_content;
	BYTE *d_block_hash;
	BYTE *difficulty;
	uint64_t nonce = 0;
	uint64_t *index;
	int *check;
	cudaMallocManaged(&check, sizeof(int));
	*check = 1;
	cudaMallocManaged(&index, sizeof(uint64_t));
	cudaMallocManaged(&d_block_hash, SHA256_HASH_SIZE * sizeof(BYTE));
	cudaMalloc((void**)&difficulty, SHA256_HASH_SIZE);
	cudaMalloc((void**)&d_block_content, BLOCK_SIZE);
	cudaMemcpy(d_block_content, block_content, BLOCK_SIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(difficulty, DIFFICULTY, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
	startTiming(&start, &stop);
	findNonce<<<numBlocks,numThreads>>>(d_block_content, current_length,d_block_hash,index,difficulty,check);
	float seconds = stopTiming(&start, &stop);
	FILE *f = fopen("results.csv", "w+");
	if (f == NULL) {
		printf("Error opening file!\n");
		return 1;
	}
	nonce = *index;
	printResult(d_block_hash, nonce, seconds);
	cudaFree(d_block_content);
	cudaFree(d_block_hash);
	cudaFree(difficulty);
	cudaFree(index);
	cudaFree(check);
	return 0;
}
