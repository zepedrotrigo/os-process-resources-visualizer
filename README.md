# Process resources

Bash script to visualize process resource usage.

![Image](/screenshots/procstat.png)

# Example Usage

```
./procstat.sh 10
```

# Parameters

- **-c:** (Optional) filter processes with a regex expression.
- **-s:** (Optional) filter by minimum process start date.
- **-e:** (Optional) filter by maximum process start date.
- **-u:** (Optional) filter by user.
- **-p:** (Optional) number of processes to display.
- **-m:** (Optional) sort by memory.
- **-t:** (Optional) sort by RSS.
- **-d:** (Optional) sort by RATER.
- **-w:** (Optional) sort by RATEW.
- **-r:** (Optional) reverse sorting.
- **int:** (Required) number of seconds to calculate I/O rates.

## Authors

- [José Trigo](https://github.com/zepedrotrigo)
- [Pedro Monteiro](https://github.com/pedromonteiro01)