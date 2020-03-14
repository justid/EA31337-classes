//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../Indicator.mqh"

// Indicator line identifiers used in Gator indicators.
enum ENUM_BWMFI_BUFFER {
  BWMFI_BUFFER = 0,
#ifdef __MQL5__
  BWMFI_HISTCOLOR = 1,
#endif
  FINAL_BWMFI_BUFFER_ENTRY
};

// Structs.
struct BWMFIParams : IndicatorParams {
  // Struct constructor.
  void BWMFIParams(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    itype = INDI_BWMFI;
    max_modes = FINAL_BWMFI_BUFFER_ENTRY;
    SetDataType(TYPE_DOUBLE);
    tf = _tf;
    tfi = Chart::TfToIndex(_tf);
  };
};

/**
 * Implements the Market Facilitation Index by Bill Williams indicator.
 */
class Indi_BWMFI : public Indicator {
 protected:
  BWMFIParams params;

 public:
  /**
   * Class constructor.
   */
  Indi_BWMFI(IndicatorParams &_params) : Indicator((IndicatorParams)_params) {}
  Indi_BWMFI(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_BWMFI, _tf) {}

  /**
   * Returns the indicator value.
   *
   * @docs
   * - https://docs.mql4.com/indicators/ibwmfi
   * - https://www.mql5.com/en/docs/indicators/ibwmfi
   */
  static double iBWMFI(string _symbol = NULL, ENUM_TIMEFRAMES _tf = PERIOD_CURRENT, int _shift = 0,
                       ENUM_BWMFI_BUFFER _mode = BWMFI_BUFFER, Indicator *_obj = NULL) {
#ifdef __MQL4__
    return ::iBWMFI(_symbol, _tf, _shift);
#else  // __MQL5__
    int _handle = Object::IsValid(_obj) ? _obj.GetState().GetHandle() : NULL;
    double _res[];
    if (_handle == NULL || _handle == INVALID_HANDLE) {
      if ((_handle = ::iBWMFI(_symbol, _tf, VOLUME_TICK)) == INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return EMPTY_VALUE;
      } else if (Object::IsValid(_obj)) {
        _obj.SetHandle(_handle);
      }
    }
    int _bars_calc = BarsCalculated(_handle);
    if (GetLastError() > 0) {
      return EMPTY_VALUE;
    } else if (_bars_calc <= 2) {
      SetUserError(ERR_USER_INVALID_BUFF_NUM);
      return EMPTY_VALUE;
    }
    if (CopyBuffer(_handle, _mode, _shift + 1, 1, _res) < 0) {
      return EMPTY_VALUE;
    }
    return _res[0];
#endif
  }

  /**
   * Returns the indicator's value.
   */
  double GetValue(ENUM_BWMFI_BUFFER _mode = BWMFI_BUFFER, int _shift = 0) {
    ResetLastError();
    istate.handle = istate.is_changed ? INVALID_HANDLE : istate.handle;
    double _value = iBWMFI(GetSymbol(), GetTf(), _shift, _mode, GetPointer(this));
    istate.is_ready = _LastError == ERR_NO_ERROR;
    istate.is_changed = false;
    return _value;
  }

  /**
   * Returns the indicator's struct value.
   */
  IndicatorDataEntry GetEntry(int _shift = 0) {
    long _bar_time = GetBarTime(_shift);
    unsigned int _position;
    IndicatorDataEntry _entry;
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      _entry.value.SetValue(params.dtype, GetValue(BWMFI_BUFFER, _shift), BWMFI_BUFFER);
#ifdef __MQL5__
      _entry.value.SetValue(params.dtype, GetValue(BWMFI_HISTCOLOR, _shift), BWMFI_HISTCOLOR);
#endif
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, _entry.value.GetValueDbl(params.dtype, BWMFI_BUFFER) != 0 && !_entry.value.HasValue(params.dtype, EMPTY_VALUE));
      idata.Add(_entry, _bar_time);
    }
    return _entry;
  }

  /**
   * Returns the indicator's entry value.
   */
  MqlParam GetEntryValue(int _shift = 0, int _mode = 0) {
    MqlParam _param = {TYPE_DOUBLE};
    _param.double_value = GetEntry(_shift).value.GetValueDbl(params.dtype, _mode);
    return _param;
  }

  /* Printer methods */

  /**
   * Returns the indicator's value in plain format.
   */
  string ToString(int _shift = 0) { return GetEntry(_shift).value.ToString(params.dtype); }
};
