<?php

/**
 * @copyright 2025 Biapy
 * @license MIT
 */

declare(strict_types=1);

use App\Kernel;

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

$env = (isset($_SERVER['APP_ENV']) && is_string($_SERVER['APP_ENV'])) ? $_SERVER['APP_ENV'] : 'dev';

return fn (array $context): Kernel => new Kernel(
    $env,
    (bool) $context['APP_DEBUG'],
);
