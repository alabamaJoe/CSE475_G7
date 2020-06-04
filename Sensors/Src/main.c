/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2020 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
	*
	******************************************************************************
	* Reference:
	* 
	* [1] Controllers Tech. "DHT11 || DHT22 || DS18B20 with STM32 using TIMER Delay," 
	* YouTube, Mar. 05, 2020 [Video file]. Available: https://www.youtube.com/wat
	* ch?v=09C1dyXvSbg&t=286s. [Accessed: Apr. 20, 2020].
	*
	* [2] MYaqoobEmbedded. "STM32F4 Discovery board - Keil 5 IDE with CubeMX: Tutorial 
	* 3 ADC single conv," YouTube, Oct. 25, 2017 [Video file]. Available: https://
	* www.youtube.com/watch?v=VaAl9hnPGiA&t=199s. [Accessed: Apr. 20, 2020].
	*
	******************************************************************************
  *
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

TIM_HandleTypeDef htim6;

UART_HandleTypeDef huart2;
DMA_HandleTypeDef hdma_usart2_rx;
/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_ADC1_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM6_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

//********************************** DHT22 functions *****************************************//
void delay (uint16_t time)
{
	/* change your code here for the delay in microseconds */
	__HAL_TIM_SET_COUNTER(&htim6, 0);
	while ((__HAL_TIM_GET_COUNTER(&htim6))<time);
}

// DHT22 variables
uint8_t Rh_byte1, Rh_byte2, Temp_byte1, Temp_byte2;
uint16_t SUM, RH, TEMP;
float Temperature = 0;
float Humidity = 0;
uint8_t Presence = 0;
// humidity data ave
float h_data1[5]; 
float h_data2[5];
float h1 = 0;
float h2 = 0;
float h3 = 0;
float h_old = 0;

// soil moisture data ave
float sm_data1[10]; 
float sm_data2[10];
float sm1;
float sm2;
float sm3;
float sm_old;

// Soil mositure variables
uint32_t moist;
float moistPercent;
const float max_moist = 3250;  // MAX: 12bit<3300>, 10bit<750>, first v 3300 when in air
const float min_moist = 1910;  // MIN: 12bit<1930>, 10bit<400>, first v 1930 when in water

#define ADC_RES_USER ADC_RESOLUTION_12B  // see MX_ADC1_Init(void)\hadc1.Init.Resolution

void Set_Pin_Output (GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = GPIO_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(GPIOx, &GPIO_InitStruct);
}

void Set_Pin_Input (GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = GPIO_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_PULLUP;
	HAL_GPIO_Init(GPIOx, &GPIO_InitStruct);
}

//********************************* DHT22 function [1] ************************************//
#define DHT22_PORT GPIOA
#define DHT22_PIN GPIO_PIN_1

// initiate DHT22 sends start signal from stm32
void DHT22_Start (void)
{
	Set_Pin_Output(DHT22_PORT, DHT22_PIN); // set the pin as output
	HAL_GPIO_WritePin (DHT22_PORT, DHT22_PIN, GPIO_PIN_RESET);   // pull the pin low, GPIO_PIN_RESET = 0
	delay(1200);   // wait for > 1ms

	HAL_GPIO_WritePin (DHT22_PORT, DHT22_PIN, GPIO_PIN_SET);   // pull the pin high, GPIO_PIN_SET = 1
	delay (20);   // wait for 30us

	Set_Pin_Input(DHT22_PORT, DHT22_PIN);   // set as input
}

// check if DHT22 starts properly
uint8_t DHT22_Check_Response (void)
{
//	Set_Pin_Input(DHT22_PORT, DHT22_PIN);   // set as input
	uint8_t Response = 0;
	delay (40);  // wait for 40us
	if (!(HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN))) // if the pin is low
	{
		delay (80);   // wait for 80us

		if ((HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN))) Response = 1;  // if the pin is high, response is ok
		else Response = -1;
	}

	while ((HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN)));   // wait for the pin to go low
	return Response;
}

// reads data from DHT22
uint8_t DHT22_Read (void)
{
	uint8_t i,j;
	for (j=0;j<8;j++)
	{
		while (!(HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN)));   // wait for the pin to go high
		delay (40);   // wait for 40 us

		if (!(HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN)))   // if the pin is low
		{
			i&= ~(1<<(7-j));   // write 0
		}
		else i|= (1<<(7-j));  // if the pin is high, write 1
		while ((HAL_GPIO_ReadPin (DHT22_PORT, DHT22_PIN)));  // wait for the pin to go low
	}

	return i;
}
//********************************* DHT22 function ends ************************************//

// convert soil sensor data from adc port [2]
void Moist_Read (void) {
	if (HAL_ADC_PollForConversion(&hadc1, 5) == HAL_OK) { // 5ms conversion
			moist = HAL_ADC_GetValue(&hadc1);
			// 3300 1910
			if (moist > max_moist) {
				moistPercent = 0.00;
			} else if (moist < min_moist) {
				moistPercent = 100;
			} else {
				
				moistPercent = -100.0 / (max_moist - min_moist) * ((float)moist - max_moist);
			}			
	} else {
			moist = -1;
			moistPercent = -1;
	}
}

//********************************* Average function ************************************//
float ave_calc(float new_data, float data_array[], int size) {
	float sum = 0;
	float ave = 0;
	float temp1 = 0;
	float temp2 = data_array[0];
	int non_zero = 0;
	
	for (int i = 0; i < size-1; i++) {
		temp1 = data_array[i+1];
		data_array[i+1] = temp2;
		temp2 = temp1;
	}
	data_array[0] = new_data;
	
	for (int i = 0; i < size; i++) {
		if (data_array[i] != 0) {
			sum += data_array[i];
			non_zero += 1;
		} 
	}
	
	if (non_zero == 0) {
		non_zero = 1;
	}
	
	ave = (float)sum/non_zero;
	
	return ave;
}

//********************************* smooth function ************************************//
//float smooth(float ave, float old_data) {
//	float output = 0;
////	if (old_data == 0) {
////		output = ave;
////	} else {
////		output = 1 * old_data + 0 * ave;
////	}
//	output = ave;
//	
//	old_data = output; 
//	
//	return output;
//}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */
  

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_ADC1_Init();
  MX_USART2_UART_Init();
  MX_TIM6_Init();
  /* USER CODE BEGIN 2 */
	// start Timer6
	HAL_TIM_Base_Start(&htim6);
	
	// text data send to UART
	char txData1[30];

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
		HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_12); // loop starts <YELLOW> 
		
    //*************************** Temp and Humid ***************************//
		DHT22_Start();
	  Presence = DHT22_Check_Response();		
		// read data from sensor 
	  Rh_byte1 = DHT22_Read ();
    Rh_byte2 = DHT22_Read ();
	  Temp_byte1 = DHT22_Read ();
	  Temp_byte2 = DHT22_Read ();
	  SUM = DHT22_Read();
		HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_15); // read function finished < BLUE>
	  TEMP = ((Temp_byte1<<8)|Temp_byte2);
	  RH = ((Rh_byte1<<8)|Rh_byte2);
		
		// converts raw data into proper numbers
	  Temperature = (float) ((TEMP-5)/10.0);
	  Humidity = (float) ((RH-35)/10.0);
		
		
		h1 = ave_calc(Humidity, h_data1, sizeof(h_data1)/sizeof(h_data1[0]));
		h2 = ave_calc(h1, h_data2, sizeof(h_data2)/sizeof(h_data2[0]));

		//***************************** Soil Moist [2] *****************************//
		HAL_ADC_Start(&hadc1);
		Moist_Read();
		HAL_ADC_Stop(&hadc1);
		HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_13); // moist read fuction finished <Orange>
		
		sm1 = ave_calc(moistPercent, sm_data1, sizeof(sm_data1)/sizeof(sm_data1[0]));
		sm2 = ave_calc(sm1, sm_data2, sizeof(sm_data2)/sizeof(sm_data2[0]));
 
		//*************************** Soild Moist ***************************//
		sprintf(txData1, "Temperature:   %5.1fC\r\nHumidity:      %5.1f%%\r\nSoil Mositure: %5.1f%%\r\n\n", Temperature, h2, sm2); 
//		sprintf(txData2, "", ); 
//		sprintf(txData3, "", ); 
		
		HAL_UART_Transmit(&huart2, (uint8_t *)txData1, strlen(txData1), 10); // 10 ms timeout
//		HAL_UART_Transmit(&huart2, (uint8_t *)txData2, strlen(txData2), 10); // 10 ms timeout
//		HAL_UART_Transmit(&huart2, (uint8_t *)txData3, strlen(txData3), 10); // 10 ms timeout
		
		HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_14); // UART finished <RED>

		// check temp and humidity every 1 s
		HAL_Delay(1000); 
		
    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}


/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage 
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC1_Init(void)
{

  /* USER CODE BEGIN ADC1_Init 0 */

  /* USER CODE END ADC1_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC1_Init 1 */

  /* USER CODE END ADC1_Init 1 */
  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion) 
  */
  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV8;
  hadc1.Init.Resolution = ADC_RES_USER;
  hadc1.Init.ScanConvMode = ENABLE;
  hadc1.Init.ContinuousConvMode = ENABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 1;
  hadc1.Init.DMAContinuousRequests = ENABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }
  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time. 
  */
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = 1;
  sConfig.SamplingTime = ADC_SAMPLETIME_480CYCLES;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC1_Init 2 */

  /* USER CODE END ADC1_Init 2 */

}

/**
  * @brief TIM6 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM6_Init(void)
{

  /* USER CODE BEGIN TIM6_Init 0 */

  /* USER CODE END TIM6_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM6_Init 1 */

  /* USER CODE END TIM6_Init 1 */
  htim6.Instance = TIM6;
  htim6.Init.Prescaler = 16-1;
  htim6.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim6.Init.Period = 0xffff-1;
  htim6.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim6) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim6, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM6_Init 2 */

  /* USER CODE END TIM6_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/** 
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void) 
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA2_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA2_Stream0_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA2_Stream0_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA2_Stream0_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_1, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_RESET);

  /*Configure GPIO pin : PA1 */
  GPIO_InitStruct.Pin = GPIO_PIN_1;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : PD12 PD13 PD14 PD15 */
  GPIO_InitStruct.Pin = GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */

  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{ 
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
