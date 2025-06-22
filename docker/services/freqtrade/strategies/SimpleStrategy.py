# READ-ONLY DATA PROVIDER STRATEGY
# This strategy is designed to NEVER place trades
# It only provides OHLCV data via Freqtrade API for analysis

import talib.abstract as ta
from freqtrade.strategy.interface import IStrategy
from pandas import DataFrame


class ReadOnlyDataProvider(IStrategy):
    """
    Read-only strategy that never enters trades.
    Used solely for providing OHLCV data via API.
    """
    
    # Strategy interface version - allows newer functionality
    INTERFACE_VERSION = 3

    # Minimal timeframe for data collection
    timeframe = '5m'
    
    # ROI table - not used since we never trade
    minimal_roi = {
        "0": 100  # Never take profit
    }

    # Stoploss - not used since we never trade  
    stoploss = -1.0  # Never stop loss

    # Never buy/sell
    use_exit_signal = False
    exit_profit_only = False
    ignore_roi_if_entry_signal = False
    
    # Startup candle count
    startup_candle_count: int = 200

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Add minimal indicators just to satisfy the interface.
        These are not used for trading decisions.
        """
        # Add basic indicators to avoid empty dataframe issues
        dataframe['sma_20'] = ta.SMA(dataframe, timeperiod=20)
        dataframe['rsi'] = ta.RSI(dataframe, timeperiod=14)
        
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        NEVER signal entry - this is a read-only data provider
        """
        # Ensure we never buy anything
        dataframe.loc[:, 'enter_long'] = False
        dataframe.loc[:, 'enter_short'] = False
        
        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        NEVER signal exit - this is a read-only data provider
        """
        # Ensure we never sell anything
        dataframe.loc[:, 'exit_long'] = False
        dataframe.loc[:, 'exit_short'] = False
        
        return dataframe 